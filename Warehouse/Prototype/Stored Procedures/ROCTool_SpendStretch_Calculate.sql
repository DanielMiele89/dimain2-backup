﻿-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <24th January 2019>
-- Description:	<Rehashed Version of SpendStretch to suit bulk addition>
-- =============================================
CREATE PROCEDURE [Prototype].[ROCTool_SpendStretch_Calculate]
	@BrandList VARCHAR(500)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Prevent table locks forming
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @time DATETIME

	EXEC Prototype.oo_TimerMessage 'ROCEFT - Spend Stretch -- Start', @time OUTPUT

	-- Create a ventiles table
	IF OBJECT_ID('Tempdb..#Ventiles') IS NOT NULL DROP TABLE #Ventiles
	CREATE TABLE #Ventiles
		(
			Number INT
			,Size REAL
			,Cumulative REAL
		)

	DECLARE @i int
	DECLARE @size real

	SET @i = 0
	SET @size = 0.05

	WHILE @i <=20
		BEGIN
			INSERT INTO #Ventiles
				SELECT	@i,
						@size,
						@i*@size
							
			SET @i = @i + 1
		END

	EXEC Prototype.oo_TimerMessage 'ROCEFT - Spend Stretch -- #Ventiles', @time OUTPUT

	-- Produce Brand(s) List that needs refreshing
	IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
	CREATE TABLE #Brand
		(	
			BrandID INT,
			BrandName VARCHAR(50)
		)

	IF @BrandList IS NULL
		BEGIN	
			INSERT INTO #Brand
				SELECT	BrandID,
						BrandName
				FROM	Warehouse.ExcelQuery.ROCEFT_BrandList

		END
	ELSE
		BEGIN
			INSERT INTO #Brand
				SELECT	BrandID,
						BrandName
				FROM	Warehouse.ExcelQuery.ROCEFT_BrandList
				WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
		END

	CREATE CLUSTERED INDEX cix_BrandID ON #Brand (BrandID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - Spend Stretch -- #Brand', @time OUTPUT

	-- Find relevant ConsumerCombinationIDs

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	cc.BrandID,
			cc.ConsumerCombinationID
	INTO	#CC
	FROM	Warehouse.Relational.ConsumerCombination cc WITH (NOLOCK)
	JOIN	#Brand br
		ON	cc.BrandID = br.BrandID

	CREATE CLUSTERED INDEX cix_ConsumerCombination ON #CC (ConsumerCombinationID)
	CREATE NONCLUSTERED INDEX nix_ConsumerCombinationID_BrandID ON #CC (ConsumerCombinationID) INCLUDE (BrandID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - Spend Stretch -- #CC', @time OUTPUT

	-- Find a 1.5m sample set of customers

	IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
	SELECT	TOP 1500000 *
	INTO	#Customer
	FROM	(
				SELECT	CINID
				FROM	Warehouse.Relational.Customer c
				JOIN	Warehouse.Relational.CINList cl
					ON	cl.CIN = c.SourceUID
				WHERE	c.CurrentlyActive = 1
					AND NOT EXISTS
						(
							SELECT	*
							FROM	Warehouse.Staging.Customer_DuplicateSourceUID dup
							WHERE	EndDate IS NULL
								AND c.SourceUID = dup.SourceUID
						)
			) a
	ORDER BY NEWID()

	CREATE CLUSTERED INDEX cix_CINID ON #Customer (CINID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - Spend Stretch -- #Customer', @time OUTPUT

	-- Min/Max TranDate

	DECLARE @StartDate DATE = DATEADD(MONTH,-12,DATEADD(DAY,-14,GETDATE()))
	DECLARE @EndDate DATE = DATEADD(DAY,-14,GETDATE())

	-- Transactions

	IF OBJECT_ID('Tempdb..#Transactions_12M') IS NOT NULL DROP TABLE #Transactions_12M
	SELECT	cc.BrandID,
			ROUND(ct.Amount,0) AS Amount,
			SUM(ct.Amount) AS Sales
	INTO	#Transactions_12M
	FROM	Warehouse.Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
	JOIN	#CC cc
		ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID 
	JOIN	#Customer c 
		ON	c.CINID = ct.CINID
	WHERE	@StartDate <= ct.TranDate AND ct.TranDate <= @EndDate
		AND 0 < Amount
	GROUP BY cc.BrandID,
			ROUND(ct.Amount,0)

	CREATE CLUSTERED INDEX cix_BrandID_Amount ON #Transactions_12M (BrandID, Amount)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - Spend Stretch -- #Transactions_12M', @time OUTPUT
	
	-- Find Total Spend

	IF OBJECT_ID('tempdb..#Transactions_12M_Total') IS NOT NULL DROP TABLE #Transactions_12M_Total
	SELECT		*
				,SUM(Sales) OVER (PARTITION BY BrandID) as TotalSales
	INTO		#Transactions_12M_Total
	FROM		#Transactions_12M 

	CREATE CLUSTERED INDEX cix_BrandID_Amount ON #Transactions_12M_Total (BrandID)
	CREATE NONCLUSTERED INDEX nix_Amount ON #Transactions_12M_Total (Amount)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - Spend Stretch -- #Transactions_12M_Total', @time OUTPUT
	
	-- Cumulative Percentage (%) of Sales
		
	IF OBJECT_ID('tempdb..#SalesPerc') IS NOT NULL DROP TABLE #SalesPerc
	SELECT	a.BrandID,
			a.Amount,
			SUM(b.Sales)/a.TotalSales AS PercentageSales,
			a.TotalSales
	INTO	#SalesPerc
	FROM	#Transactions_12M_Total a
	JOIN	#Transactions_12M_Total b 
		ON	a.BrandID = b.BrandID
		AND a.Amount <= b.Amount 
	GROUP BY a.BrandID,
			a.Amount,
			a.TotalSales
	ORDER BY 1,2

	CREATE CLUSTERED INDEX cix_PercentageSales ON #SalesPerc (PercentageSales)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - Spend Stretch -- #SalesPerc', @time OUTPUT

	-- TRUNCATE / DELETE JUST BEFORE INSERTION

	-- INSERT STATEMENT HERE
	IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output
	SELECT	BrandID,
			Cumulative,
			MAX(Amount) AS Boundary
	INTO	#Output
	FROM	#Ventiles a
	JOIN	#SalesPerc b 
		ON	b.PercentageSales >= a.Cumulative
	GROUP BY BrandID,
			Cumulative
	ORDER BY BrandID,
			Cumulative

	EXEC Prototype.oo_TimerMessage 'ROCEFT - Spend Stretch -- #Output', @time OUTPUT
	
	IF @BrandList IS NULL 
		BEGIN
			TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_SpendStretch
		END
	ELSE
		BEGIN
			DELETE FROM Warehouse.ExcelQuery.ROCEFT_SpendStretch
			WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
		END

	INSERT INTO Warehouse.ExcelQuery.ROCEFT_SpendStretch
		SELECT	*
		FROM	#Output
		ORDER BY 1,2

END
