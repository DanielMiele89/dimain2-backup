-- =============================================
-- Author:		<Shaun H.>
-- Create date: <21/06/2017>
-- Description:	<Description,,>
-- =============================================

--MS Edited lines 132/133 is refund no longer exists on cc_myrewards, replaced with amount>0  12/06/2018 

CREATE PROCEDURE [ExcelQuery].[ROCEFT_SpendStretch_Calculate] @BrandID int
	WITH EXECUTE AS OWNER --JEA 12/06/2018 added because of the truncate below
AS
BEGIN
	SET NOCOUNT ON;

	--DECLARE @BrandID Int
	--SET @BrandID = 75

	IF OBJECT_ID('Tempdb..#WorkingBrands') IS NOT NULL DROP TABLE #WorkingBrands
	CREATE TABLE #WorkingBrands
	(ID Int Identity(1,1) primary key clustered,
	BrandID Int)
	
	--  "IF" statement to deal with a refresh of a single brand or all brands
	IF @BrandID IS NULL
	BEGIN
		
		INSERT INTO #WorkingBrands (BrandID)
		SELECT	BrandID
		FROM	Warehouse.ExcelQuery.ROCEFT_BrandList
		
		-- Append current ROCEFT_SpendStretch to the archive table, and truncate the ROCEFT_SpendStretch table
		INSERT INTO Warehouse.InsightArchive.ROCEFT_SpendStretch_Archive
		SELECT		CAST(GETDATE() as date) as BackupDate,
					BrandID,
					Cumu_Percentage,
					Boundary
		FROM		Warehouse.ExcelQuery.ROCEFT_SpendStretch
		
		TRUNCATE TABLE  Warehouse.ExcelQuery.ROCEFT_SpendStretch

	END
	ELSE
	BEGIN
		INSERT INTO #WorkingBrands (BrandID)
		VALUES (@BrandID)

		DELETE FROM	Warehouse.ExcelQuery.ROCEFT_SpendStretch WHERE BrandID = @BrandID
	END

	


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




	DECLARE @Brand_loop INT
	DECLARE @maxID Int


	SET @i = 1
	SET @maxID = (Select max(id) from #WorkingBrands)

	WHILE @i <= @maxID
		BEGIN
				-- Create a single brand brand table
				IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
				SELECT	*
				INTO	#Brand
				FROM	#WorkingBrands
				WHERE	ID = @i

				IF OBJECT_ID('Tempdb..#CC') IS NOT NULL DROP TABLE #CC
				SELECT	DISTINCT ConsumerCombinationID
				INTO	#CC
				FROM	Warehouse.Relational.ConsumerCombination cc
				INNER JOIN #Brand b on b.BrandID = cc.brandid
				
				CREATE CLUSTERED INDEX ix_CC ON #CC(ConsumerCombinationID)

				IF OBJECT_ID('Tempdb..#CustGroup') IS NOT NULL DROP TABLE #Custgroup
				SELECT		DISTINCT FanID
							,CINID
				INTO		#CustGroup
				FROM		Warehouse.Relational.customer c
				JOIN		Warehouse.Relational.CINList cl ON cl.cin = c.sourceuid
				WHERE		c.CurrentlyActive = 1
						AND DATEADD(MONTH,-12,GETDATE()) <= c.ActivatedDate

				CREATE CLUSTERED INDEX ix_CINID ON #CustGroup(CINID)

				DECLARE @StartDate DATE = DATEADD(MONTH,-12,DATEADD(DAY,-14,GETDATE()))
				DECLARE @EndDate DATE = DATEADD(DAY,-14,GETDATE())

				IF OBJECT_ID('Tempdb..#Txns12m') IS NOT NULL DROP TABLE #Txns12m
				SELECT		ROUND(Amount,0) as Amount
							,SUM(Amount) as Sales
				INTO		#Txns12m
				FROM		Warehouse.Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
				JOIN		#CC cc ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID 
				JOIN		#CustGroup c ON c.CINID = ct.CINID
				WHERE		TranDate BETWEEN @StartDate AND @EndDate
				--		AND IsRefund = 0 --Change by MS 12/06/2018
						AND Amount > 0 --Change by MS 12/06/2018
				GROUP BY	ROUND(Amount,0)

				CREATE CLUSTERED INDEX Idx_amt ON #Txns12m(Amount)

				IF OBJECT_ID('Tempdb..#Txns12m_1') IS NOT NULL DROP TABLE #Txns12m_1
				SELECT		a.*
							,sum(Sales) over () as TotalSales
				INTO		#Txns12m_1
				FROM		#Txns12m a
			
				IF OBJECT_ID('Tempdb..#SalesPerc') IS NOT NULL DROP TABLE #SalesPerc
				SELECT		a.Amount
							,SUM(b.Sales)/a.TotalSales as PercentageSales
							,a.TotalSales
				INTO		#SalesPerc
				FROM		#Txns12m_1 a
				JOIN		#Txns12m_1 b on a.Amount <= b.Amount 
				GROUP BY	a.Amount, a.totalsales
				ORDER BY	a.Amount

				INSERT INTO Warehouse.ExcelQuery.ROCEFT_SpendStretch(BrandID, Cumu_Percentage, Boundary)
					SELECT		@BrandID
								,Cumulative
								,MAX(Amount) as Boundary
					FROM		#Ventiles a
					JOIN		#SalesPerc b on b.PercentageSales >= a.Cumulative
					GROUP BY	Cumulative
					ORDER BY	Cumulative

				SET @i = @i + 1
		END


END
