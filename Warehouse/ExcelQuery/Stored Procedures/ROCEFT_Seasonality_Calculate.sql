-- =============================================
-- Author:		<Shaun H.>
-- Create date: <21/06/2017>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_Seasonality_Calculate] @BrandID int
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @ArchiveDate DATE
	DECLARE @sql Varchar(max)
	--DECLARE @BrandID Int
	--SET @BrandID = NULL

	SET @ArchiveDate = CAST(GETDATE() as DATE)

	IF OBJECT_ID('Tempdb..#AllBrands') IS NOT NULL DROP TABLE #AllBrands
	CREATE TABLE #AllBrands
	(ID Int Identity(1,1) primary key clustered,
	BrandID Int)
	

	--  "IF" statement to deal with a refresh of a single brand or all brands
	IF @BrandID IS NULL
	BEGIN
			
		INSERT INTO #AllBrands (BrandID)
		SELECT	BrandID
		FROM	Warehouse.ExcelQuery.ROCEFT_BrandList
		
		IF OBJECT_ID('Warehouse.InsightArchive.ROCEFT_Seasonality_Backup') IS NOT NULL
		BEGIN
			SET @sql = '
			SELECT *
			INTO Warehouse.InsightArchive.ROCEFT_Seasonality_Backup_'+cast(@ArchiveDate as Varchar(max))+'
			FROM Warehouse.InsightArchive.ROCEFT_Seasonality_Backup'

			EXEC (@Sql)

			DROP TABLE Warehouse.InsightArchive.ROCEFT_Seasonality_Backup
		END

		SELECT *
		INTO Warehouse.InsightArchive.ROCEFT_Seasonality_Backup
		FROM Warehouse.ExcelQuery.ROCEFT_Seasonality 

		TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_Seasonality 
		
	END
	ELSE
	BEGIN
		INSERT INTO #AllBrands (BrandID)
		VALUES (@BrandID)

		DELETE FROM Warehouse.ExcelQuery.ROCEFT_Seasonality WHERE BrandID = @BrandID
	END
	
	SET DATEFIRST 1

	-- Create ROC Cycle Calendar
	IF OBJECT_ID('Tempdb..#SeasonalCalendar') IS NOT NULL DROP TABLE #SeasonalCalendar
	SELECT		ID as Seasonality_Cycle,
				DATEPART(YYYY,CycleStart) as Seasonality_Year,
				CycleStart,
				CycleEnd
	INTO		#SeasonalCalendar
	FROM		Warehouse.ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended
	WHERE		ID <= 13
	UNION
	SELECT		ID as Seasonlity_Cycle,
				DATEPART(YYYY,DATEADD(yyyy, -1, CycleStart)) as Seasonality_Year,
				CASE
					WHEN DATEPART(dw, DATEADD(yyyy, -1, CycleStart)) = 4 THEN DATEADD(yyyy, -1, CycleStart)
					WHEN DATEPART(dw, DATEADD(yyyy, -1, CycleStart)) <> 4 THEN  DATEADD(d, 4 - DATEPART(dw, DATEADD(yyyy, -1, CycleStart)), DATEADD(yyyy, -1, CycleStart))
				END	as CycleStartY1,
				CASE	WHEN DATEPART(dw, DATEADD(yyyy, -1, CycleEnd)) = 3 THEN DATEADD(yyyy, -1, CycleEnd)
						WHEN DATEPART(dw, DATEADD(yyyy, -1, CycleEnd)) <> 3 THEN  DATEADD(d, 3 - DATEPART(dw, DATEADD(yyyy, -1, CycleEnd)), DATEADD(yyyy, -1, CycleEnd))
				END as CycleEndY1
	FROM		Warehouse.ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended
	WHERE		ID <= 13
	UNION
	SELECT		ID as Seasonlity_Cycle,
				DATEPART(YYYY,DATEADD(yyyy, -2, CycleStart)) as Seasonality_Year,

				CASE	WHEN DATEPART(dw, DATEADD(yyyy, -2, CycleStart)) = 4 THEN DATEADD(yyyy, -2, CycleStart)
						WHEN DATEPART(dw, DATEADD(yyyy, -2, CycleStart)) <> 4 THEN  DATEADD(d, 4 - DATEPART(dw, DATEADD(yyyy, -2, CycleStart)), DATEADD(yyyy, -2, CycleStart))
				END as CycleStartY2,
				CASE	WHEN DATEPART(dw, DATEADD(yyyy, -2, CycleEnd)) = 3 THEN DATEADD(yyyy, -2, CycleEnd)
						WHEN DATEPART(dw, DATEADD(yyyy, -2, CycleEnd)) <> 3 THEN  DATEADD(d, 3 - DATEPART(dw, DATEADD(yyyy, -2, CycleEnd)), DATEADD(yyyy, -2, CycleEnd))
				END as CycleEndY2
	FROM		Warehouse.ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended
	WHERE		ID <= 13
	UNION
	SELECT		ID as Seasonlity_Cycle,
				DATEPART(YYYY,DATEADD(yyyy, -3, CycleStart)) as Seasonality_Year,
				CASE	WHEN DATEPART(dw, DATEADD(yyyy, -3, CycleStart)) = 4 THEN DATEADD(yyyy, -3, CycleStart)
						WHEN DATEPART(dw, DATEADD(yyyy, -3, CycleStart)) <> 4 THEN  DATEADD(d, 4 - DATEPART(dw, DATEADD(yyyy, -3, CycleStart)), DATEADD(yyyy, -3, CycleStart))
				END as CycleStartY3,
				CASE	WHEN DATEPART(dw, DATEADD(yyyy, -3, CycleEnd)) = 3 THEN DATEADD(yyyy, -3, CycleEnd)
						WHEN DATEPART(dw, DATEADD(yyyy, -3, CycleEnd)) <> 3 THEN  DATEADD(d, 3 - DATEPART(dw, DATEADD(yyyy, -3, CycleEnd)), DATEADD(yyyy, -3, CycleEnd))
				END as CycleEndY3
	FROM		Warehouse.ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended
	WHERE		ID <= 13

	CREATE CLUSTERED INDEX Idx_CStart on #SeasonalCalendar(CycleStart)

	-- SELECT * FROM #SeasonalCalendar

	-- MyRewards Base (Full) that have registered after 1st January 2014
	IF OBJECT_ID('tempdb..#MyRewardsBase') IS NOT NULL DROP TABLE #MyRewardsBase
	SELECT	*
	INTO	#MyRewardsBase
	FROM	(
				SELECT	DISTINCT cl.CINID
						,'My Rewards' as Segment
				FROM	Warehouse.Relational.Customer c
				JOIN	Warehouse.Relational.CINList cl ON cl.CIN = c.SourceUID
				WHERE	c.CurrentlyActive = 1
					AND	NOT EXISTS (
										SELECT	*
										FROM	Warehouse.Staging.Customer_DuplicateSourceUID dup
										WHERE	EndDate IS NULL
											AND c.SourceUID = dup.SourceUID
									)
			) a
	ORDER BY NEWID()

	CREATE CLUSTERED INDEX ix_ccID ON #MyRewardsBase(CINID)

	DELETE FROM	#MyRewardsBase
		WHERE	CINID in (	SELECT	CINID 
							FROM	Warehouse.Relational.CINList cl 
							JOIN 	SLC_Report.dbo.Fan f ON cl.CIN = f.sourceUID 
							WHERE	'2014-01-01' < RegistrationDate )

	DECLARE	@CurrentCycle Int
	SET @CurrentCycle = (
							SELECT	Seasonality_Cycle
							FROM	#SeasonalCalendar
							WHERE	DATEADD(week,-1,CAST(GETDATE() as Date)) between CycleStart AND CycleEnd
						)

	DECLARE @NumBrands Int
	DECLARE @i int
	DECLARE @Brand_Loop Int


	SET @i = 1
	SET @NumBrands = (SELECT Max(ID) from #AllBrands)

	WHILE @i <= @NumBrands
	BEGIN
				-- Create a single brand brand table
				IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
				SELECT	BrandID
				INTO	#Brand
				FROM	#AllBrands WITH (NOLOCK)
				WHERE	ID = @i

				SET @Brand_Loop = (SELECT BrandID FROM #Brand)

				-- ConsumerCombinationIDs
				IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
				SELECT	DISTINCT cc.BrandID
						,ConsumerCombinationID
				INTO	#CC
				FROM	Warehouse.Relational.ConsumerCombination cc
				INNER JOIN #Brand b on cc.BrandID = b.BrandID
				
				CREATE CLUSTERED INDEX ix_brandID on #cc(BrandID)
				CREATE NONCLUSTERED INDEX ix_ccID on #cc(ConsumerCombinationID)

				--  Create Seasonality Summary data
				DECLARE @LimitDate DATE = (SELECT CycleEnd FROM #SeasonalCalendar WHERE Seasonality_Year = DATEPART(yyyy, GETDATE()) AND Seasonality_Cycle = (@CurrentCycle - 1))

				IF OBJECT_ID('Tempdb..#SeasonalSummary') IS NOT NULL DROP TABLE #Seasonalsummary
				SELECT		cc.BrandID
							,a.Seasonality_Cycle
							,SUM(ct.Amount) AS Spend
							,COUNT(*) AS Transactions
							,COUNT(DISTINCT ct.CINID) AS Spenders
							,COUNT(DISTINCT a.Seasonality_Year) AS Years
				INTO		#SeasonalSummary
				FROM		#SeasonalCalendar a
				INNER JOIN	Warehouse.Relational.ConsumerTransaction ct with (nolock)
						ON	ct.TranDate between a.CycleStart AND a.CycleEnd
				INNER JOIN	#CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				INNER JOIN	#MyRewardsBase m on m.CINID = ct.CINID
				WHERE		TranDate <= @LimitDate
				GROUP BY	cc.BrandID
							,a.Seasonality_Cycle

				INSERT INTO Warehouse.ExcelQuery.ROCEFT_Seasonality 
					SELECT		BrandID,
								Seasonality_Cycle,
								Spend/Years/ExpectedSpend as Spend_Index,
								Transactions*1.0/Years/ExpectedTransactions as Txns_Index,
								Spenders*1.0/Years/ExpectedSpenders as Spenders_Index
					FROM		#SeasonalSummary a
					CROSS JOIN	(SELECT		sum(Spend)/Sum(Years) as ExpectedSpend,
											Sum(Transactions)*1.0/Sum(Years) as ExpectedTransactions,
											Sum(spenders)*1.0/Sum(Years) as ExpectedSpenders
								FROM		#SeasonalSummary) b

				-- Increment
				SET @i = @i + 1
		END

END