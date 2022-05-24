-- =================================================================================
-- Author:		<Shaun Hide>
-- Create date: <30th March 2017>
-- Update v1: Add in additional elements needed to implement seasonality
-- Description:	<Brand Seasonality>
-- =================================================================================
CREATE PROCEDURE [Prototype].[AMEX_Seasonality_v1]
	(
		@Brand INT
	)
AS
BEGIN
	SET NOCOUNT ON;

	--DECLARE @Brand INT = NULL
	DECLARE @TodayDate DATE = DATEADD(DAY,-7,GETDATE())
	DECLARE @EndDate DATE	= EOMONTH(DATEADD(MONTH,-MONTH(EOMONTH(@TodayDate)),EOMONTH(@TodayDate)))
	DECLARE @StartDate DATE = DATEADD(YEAR,-1,DATEADD(DAY,1,@EndDate))

	----------------------------------------------------------------------------------------
	----------  Get Customer Base
	----------------------------------------------------------------------------------------
	--IF object_id('Warehouse.InsightArchive.SalesVisSuite_FixedBase') IS NOT NULL DROP TABLE Warehouse.InsightArchive.SalesVisSuite_FixedBase
	--EXEC Warehouse.Relational.CustomerBase_Generate'SalesVisSuite_FixedBase', @StartDate, @EndDate

	IF OBJECT_ID('tempdb..#Population') IS NOT NULL DROP TABLE #Population
	SELECT	TOP 1500000 *
	INTO	#Population
	FROM	Warehouse.InsightArchive.SalesVisSuite_FixedBase
	ORDER BY NEWID()

	CREATE CLUSTERED INDEX ix_CINID ON #Population(CINID)

	----------------------------------------------------------------------------------------
	----------  Setup Brand Loop
	----------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
	CREATE TABLE #Brand
		(
			RowNo INT
			,BrandID INT
		)
	DECLARE @BrandN VARCHAR(50)

	IF @Brand IS NULL
		BEGIN
			INSERT INTO #Brand
				SELECT	ROW_NUMBER() OVER (ORDER BY BrandID) AS RowNo
						,BrandID
				FROM	(	SELECT	DISTINCT br.BrandID
							FROM	Warehouse.Prototype.AMEX_BrandList b
							JOIN	Warehouse.Relational.Brand br
								ON	b.[BrandID] = br.[BrandID]) a
			IF OBJECT_ID('Warehouse.Prototype.AMEX_Seasonality_v2') IS NOT NULL TRUNCATE TABLE Warehouse.Prototype.AMEX_Seasonality_v2
		END
	ELSE
		BEGIN
			INSERT INTO #Brand
				SELECT	1 AS RowNo
						,@Brand as BrandID

			SET @BrandN = (SELECT  BrandName
						   FROM	   Warehouse.Relational.Brand
						   WHERE   BrandID = @Brand)
			
			DELETE	FROM Warehouse.Prototype.AMEX_Seasonality_v2
			WHERE	BrandName = @BrandN
			
		END

	CREATE CLUSTERED INDEX ix_RowNo ON #Brand (RowNo)
	CREATE NONCLUSTERED INDEX ix_BrandID ON #Brand (BrandID)

	-- SELECT * FROM #Brand WHERE BrandID =425

	DECLARE @i INT = 1
	DECLARE @BrandID INT 
	DECLARE @BrandName VARCHAR(50)

	WHILE @i <= (SELECT COUNT(*) FROM #Brand)
		BEGIN
			SET @BrandID = (SELECT BrandID FROM #Brand WHERE RowNo = @i)	
			SET	@BrandName = (SELECT BrandName
							  FROM	 Warehouse.Relational.Brand
							  WHERE	 BrandID = @BrandID)

			----------------------------------------------------------------------------------------
			----------  Find ConsumerCombinations
			----------------------------------------------------------------------------------------

			IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
			SELECT	cc.BrandID
					,@BrandName AS BrandName
					,cc.ConsumerCombinationID
			INTO	#CC
			FROM	Warehouse.Relational.ConsumerCombination cc
			WHERE	BrandID = @BrandID

			CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #CC(ConsumerCombinationID)
			CREATE NONCLUSTERED INDEX nix_BrandID ON #CC(BrandID)

			----------------------------------------------------------------------------------------
			----------  Find Transactions
			----------------------------------------------------------------------------------------

			IF OBJECT_ID('tempdb..#CINTrans') IS NOT NULL DROP TABLE #CINTrans
			SELECT	ct.CINID
					,ct.Amount
					,ct.IsOnline
					,ct.TranDate
			INTO	#CINTrans
			FROM	Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
			JOIN	#CC cc
				ON	ct.ConsumerCombinationID = cc.ConsumerCombinationID
			JOIN	#Population fb
				ON	ct.CINID = fb.CINID
			 WHERE	ct.TranDate BETWEEN @StartDate and @EndDate

			 CREATE CLUSTERED INDEX CIX_CinTrans_Main ON #CinTrans (TranDate)
			 CREATE NONCLUSTERED INDEX NIX_CinTrans_Secondary ON #CinTrans (TranDate) INCLUDE (CINID)

			IF OBJECT_ID('tempdb..#YearShoppers') IS NOT NULL DROP TABLE #YearShoppers
			SELECT		DATEPART(YYYY,TranDate) AS Year
						,COUNT(DISTINCT CINID) AS Year_Shoppers
			INTO		#YearShoppers
			FROM		#CINTrans
			GROUP BY	DATEPART(YYYY,TranDate)
			ORDER BY	DATEPART(YYYY,TranDate)
				
			CREATE CLUSTERED INDEX cix_Year ON #YearShoppers(Year)

			INSERT INTO Warehouse.Prototype.AMEX_Seasonality_v2
				SELECT		MonthNum
							,a.Year
							,YYYYMM
							,BrandName
							,All_Sales
							,All_Trans
							,All_Shoppers
							,Year_Shoppers
							,Online_Sales
							,Online_Trans
							,Store_Sales
							,Store_Trans
				FROM		(	SELECT		DATEPART(mm,TranDate) as MonthNum
											,DATEPART(yyyy,TranDate) as Year
											,CAST(LEFT(CONVERT(VARCHAR,TranDate,112),6) AS NUMERIC) as YYYYMM
											,@BrandName AS BrandName
											,SUM(Amount) as All_sales
											,COUNT(1) as All_trans
											,COUNT(DISTINCT CINID) AS All_Shoppers
											,SUM(CASE WHEN IsOnline=1 THEN Amount ELSE 0 END) as Online_sales
											,SUM(CASE WHEN IsOnline=1 THEN 1 ELSE 0 END) as Online_trans
											,SUM(CASE WHEN IsOnline=0 THEN Amount ELSE 0 END) as Store_Sales
											,SUM(CASE WHEN IsOnline=0 THEN 1 ELSE 0 End) as Store_trans
								FROM		#CINTrans
								GROUP BY	DATEPART(mm,TranDate)
											,DATEPART(yyyy,TranDate)
											,CAST(LEFT(CONVERT(VARCHAR,TranDate,112),6) AS NUMERIC)
								) a
				JOIN		#YearShoppers y
						ON	a.Year = y.Year
				ORDER BY	YYYYMM

			OPTION (RECOMPILE)
			
			SET @i = @i + 1
		END

	------------------------------------------------------------------------------
	END