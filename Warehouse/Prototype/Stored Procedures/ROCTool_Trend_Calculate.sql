-- =============================================
-- Author:		<Tasfia Uddin>
-- Create date: <17/01/2018>
-- Description:	<ROC Tool Trend Calculation>
-- =============================================
CREATE PROCEDURE [Prototype].[ROCTool_Trend_Calculate]

	@BrandList VARCHAR(500) 

	AS
	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @time DATETIME

    -- Insert statements for procedure here
	EXEC Prototype.oo_TimerMessage 'ROCEFT - TrendCalculation -- Start', @time OUTPUT

	IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
	CREATE TABLE #Brand
		(
			BrandID INT NOT NULL PRIMARY KEY
			,BrandName VARCHAR(50)
			,RowNo INT
		)

	IF @BrandList IS NULL
		BEGIN
			INSERT INTO #Brand
				SELECT	BrandID
						,BrandName
						,ROW_NUMBER() OVER (ORDER BY BrandID) RowNo
				FROM	Warehouse.ExcelQuery.ROCEFT_BrandList
		END
	ELSE
		BEGIN
			INSERT INTO #Brand
				SELECT	BrandID
						,BrandName
						,ROW_NUMBER() OVER (ORDER BY BrandID) RowNo
				FROM	Warehouse.ExcelQuery.ROCEFT_BrandList
				WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
		END
	
	EXEC Prototype.oo_TimerMessage 'ROCEFT - TrendCalculation -- #Brand', @time OUTPUT

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	cc.BrandID,
			cc.ConsumerCombinationID
	INTO	#CC
	FROM	Warehouse.Relational.ConsumerCombination cc WITH (NOLOCK)
	JOIN	#Brand br
		ON	cc.BrandID = br.BrandID

	CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #CC (ConsumerCombinationID)
	CREATE NONCLUSTERED INDEX nix_ConsumerCombinationID_BrandID ON #CC (ConsumerCombinationID) INCLUDE (BrandID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - TrendCalculation -- #CC', @time OUTPUT

	----------------------------------------------------------------------------------------------
	-- Fixed Base - Find a random 1.5m MyRewards Customers

	IF OBJECT_ID('tempdb..#MyRewardsBase') IS NOT NULL DROP TABLE #MyRewardsBase
	SELECT	TOP 1500000 *
	INTO	#MyRewardsBase
	FROM	(
				SELECT	DISTINCT CINID, CompositeID
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

	CREATE CLUSTERED INDEX cix_CINID ON #MyRewardsBase(CINID)
	CREATE NONCLUSTERED INDEX nix_CINID ON #MyRewardsBase(CompositeID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - TrendCalculation -- #MyRewardsBase', @time OUTPUT

	---------------------------------------------------------------------------------------------
	-- Dates - Generate a Dates Table (Aligns with the other Dates Table)
	
	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
	CREATE TABLE #Dates
		(
			ID INT NOT NULL PRIMARY KEY
			,CycleStart DATE
			,CycleEnd DATE
			,Seasonality_CycleID INT
		)

	;WITH CTE
	 AS (	
			SELECT	1 AS ID
					,CAST('2015-04-02' AS DATE) AS CycleStart
					,CAST('2015-04-29' AS DATE) AS CycleEnd
					,4 AS Seasonality_CycleID
		
			UNION ALL
		
			SELECT	ID + 1
					,CAST(DATEADD(DAY,28,CycleStart) AS DATE)
					,CAST(DATEADD(DAY,28,CycleEnd) AS DATE)
					,CASE
						WHEN Seasonality_CycleID < 13 THEN Seasonality_CycleID + 1
						ELSE Seasonality_CycleID - 12
					 END
			FROM	CTE
			WHERE	ID < 100
		)
	INSERT INTO #Dates
		SELECT	* 
		FROM	CTE
	OPTION (MAXRECURSION 100)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - TrendCalculation -- #Dates', @time OUTPUT

	IF OBJECT_ID('tempdb..#WorkingDates') IS NOT NULL DROP TABLE #WorkingDates
	SELECT	b.*
			,ROW_NUMBER() OVER (ORDER BY b.ID ASC) AS DateRow
	INTO	#WorkingDates
	FROM	(SELECT	*
			 FROM	#Dates 
			 WHERE	CycleStart <= CAST(DATEADD(DAY,-7,GETDATE()) AS DATE)
				AND CAST(DATEADD(DAY,-7,GETDATE()) AS DATE) <= CycleEnd) a
	JOIN	#Dates b
		ON  a.ID - 40 < b.ID
		AND b.ID < a.ID

	CREATE CLUSTERED INDEX cix_DateRow ON #WorkingDates(DateRow)
	CREATE NONCLUSTERED INDEX nix_CycleStart ON #WorkingDates(CycleStart)
	CREATE NONCLUSTERED INDEX nix_CycleEnd ON #WorkingDates(CycleEnd)
	
	EXEC Prototype.oo_TimerMessage 'ROCEFT - TrendCalculation -- #WorkingDates', @time OUTPUT

	DECLARE @MinTranDate DATE,
			@MaxTranDate DATE
	SELECT	@MinTranDate = MIN(CycleStart),
			@MaxTranDate = MAX(CycleEnd)
	FROM	#WorkingDates

	IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL DROP TABLE #Transactions
	SELECT	BrandID,
			TranDate,
			IsOnline,
			SUM(Amount) AS Sales,
			COUNT(1) AS Transactions
	INTO	#Transactions
	FROM	Warehouse.Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
	JOIN	#CC cc
		ON	ct.ConsumerCombinationID = cc.ConsumerCombinationID
	JOIN	#MyRewardsBase c
		ON	ct.CINID = c.CINID
	WHERE	0 < ct.Amount
		AND	@MinTranDate <= ct.TranDate AND ct.TranDate <= @MaxTranDate
	GROUP BY BrandID,
			TranDate,
			IsOnline

	CREATE CLUSTERED INDEX cix_TranDate ON #Transactions (TranDate)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - TrendCalculation -- #Transactions', @time OUTPUT

	IF @BrandList IS NULL
		BEGIN
			TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_Trend
		END
	ELSE
		BEGIN
			DELETE FROM Warehouse.ExcelQuery.ROCEFT_Trend
			WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0	
		END
	
	EXEC Prototype.oo_TimerMessage 'ROCEFT - TrendCalculation -- Clean Up Table', @time OUTPUT

	INSERT INTO Warehouse.ExcelQuery.ROCEFT_Trend
		SELECT	w.ID,
				w.CycleStart,
				w.CycleEnd,
				w.Seasonality_CycleID,
				t.BrandID,
				SUM(Sales) AS TotalSales,
				SUM(CASE WHEN IsOnline=0 THEN Sales ELSE 0 END) AS InStoreSales,
				SUM(CASE WHEN IsOnline=1 THEN Sales ELSE 0 END) AS OnlineSales,
				SUM(Transactions) AS TotalTransactions,
				SUM(CASE WHEN IsOnline=0 THEN Transactions ELSE 0 END) AS InStoreTransactions,
				SUM(CASE WHEN IsOnline=1 THEN Transactions ELSE 0 END) AS OnlineTransactions,
				AVG(m.MinID) AS MinID,
				AVG(m.MaxID) AS MaxID
		FROM	#WorkingDates w
		CROSS JOIN 
			(	SELECT	MIN(ID) AS MinID,
						MAX(ID) AS MaxID
				FROM	#WorkingDates	) m
		JOIN	#Transactions t
			ON	w.CycleStart <= t.TranDate AND t.TranDate <= w.CycleEnd
		GROUP BY w.ID,
				 w.CycleStart,
				 w.CycleEnd,
				 w.Seasonality_CycleID,
				 t.BrandID 
		ORDER BY 5,1

	EXEC Prototype.oo_TimerMessage 'ROCEFT - TrendCalculation -- End', @time OUTPUT

	--IF OBJECT_ID('Warehouse.ExcelQuery.ROCEFT_Trend') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.ROCEFT_Trend
	--CREATE TABLE Warehouse.ExcelQuery.ROCEFT_Trend
	--	(	
	--		ID INT NOT NULL,
	--		CycleStart DATE NOT NULL,
	--		CycleEnd DATE NOT NULL,
	--		Seasonality_CycleID INT NOT NULL,
	--		BrandID INT NOT NULL,
	--		TotalSales MONEY,
	--		InStoreSales MONEY,
	--		OnlineSales MONEY,
	--		TotalTransactions INT,
	--		InStoreTransactions INT,
	--		OnlineTransactions INT,
	--		MinID INT NOT NULL,
	--		MaxID INT NOT NULL,
	--		PRIMARY KEY (BrandID, ID)
	--	)

	
	-- Retrieval Script
	--DECLARE @BrandID INT = 292

	--SELECT	*
	--FROM	Warehouse.ExcelQuery.ROCEFT_Trend
	--WHERE	BrandID = @BrandID
	--ORDER BY 1




END
