-- =============================================
-- Author:		Beyers Geldenhuys
-- Create date: 20/06/2017
-- Description:	Stored Procedure that generates natural spend data for 
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_NaturalSales_Calculate_v2]
	(@BrandID INT)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @BackupDate DATE
	DECLARE @SQL Varchar(max)
	
	--DECLARE @BrandID INT = 1622
	--SELECT * FROM Warehouse.Relational.Brand Where BrandID = 425
	
	SET @Backupdate = GETDATE()


	IF OBJECT_ID('Tempdb..#AllBrands') IS NOT NULL DROP TABLE #AllBrands
	CREATE TABLE #AllBrands
		(
			ID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED
			,BrandID INT
		)

	--"IF" statement to deal with a refresh of a single brand or all brands
	IF @BrandID IS NULL
		BEGIN
			--Archive previous version and truncate table
			SET @SQL = 	'SELECT	* 
						 INTO	Warehouse.InsightArchive.ROCEFT_NaturalSpend_'+ REPLACE(CAST(@BackupDate as Varchar(max)),'-','') +'
						 FROM	Warehouse.InsightArchive.ROCEFT_NaturalSpend_Backup'
			EXEC (@SQL)

			DROP TABLE Warehouse.InsightArchive.ROCEFT_NaturalSpend_Backup

			SELECT	* 
			INTO	Warehouse.InsightArchive.ROCEFT_NaturalSpend_Backup
			FROM	Warehouse.ExcelQuery.ROCEFT_NaturalSpend

			SET @SQL = 	'SELECT	* 
						 INTO	Warehouse.InsightArchive.ROCEFT_IncentivisedSpend_'+ REPLACE(CAST(@BackupDate as Varchar(max)),'-','') +'
						 FROM	Warehouse.InsightArchive.ROCEFT_IncentivisedSpend_Backup'
			EXEC (@SQL)

			DROP TABLE Warehouse.InsightArchive.ROCEFT_IncentivisedSpend_Backup

			SELECT	* 
			INTO	Warehouse.InsightArchive.ROCEFT_IncentivisedSpend_Backup
			FROM	Warehouse.ExcelQuery.ROCEFT_IncentivisedSpend

			TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_NaturalSpend
			TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_IncentivisedSpend
		
			INSERT INTO #AllBrands (BrandID)
				SELECT	BrandID
				FROM	Warehouse.ExcelQuery.ROCEFT_BrandList
		END
	ELSE
		BEGIN
			INSERT INTO #AllBrands (BrandID)
				VALUES (@BrandID)
			DELETE	FROM	Warehouse.ExcelQuery.ROCEFT_NaturalSpend WHERE BrandID = @BrandID
			DELETE	FROM	Warehouse.ExcelQuery.ROCEFT_IncentivisedSpend WHERE BrandID = @BrandID
		END

	--SELECT * FROM #AllBrands


	DECLARE	@CurrentCycle Int
	DECLARE @CycleIDRef	Int
	DECLARE @i int
	DECLARE @NumBrands Int

	/*	Define Current Cycle (@CurrentCycle) & Cycle (@CycleIDRef) we will look at:
		- Allow for a week lag in the data stream
		- Find which cycle this GETDATE - 1 Week is
		- CycleIDRef will be the last COMPLETE cycle (i.e. @CurrentCycle - 1)
	*/
	SET DATEFIRST 1

	SET @CurrentCycle = (SELECT ID
						 FROM	Warehouse.ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended
						 WHERE	DATEADD(WEEK,-1,CAST(GETDATE() AS DATE)) BETWEEN CycleStart AND CycleEnd)
	SET @CycleIDRef = @currentCycle - 1


	IF OBJECT_ID('tempdb..#DateRanges') IS NOT NULL DROP TABLE #DateRanges
	SELECT		CAST(GETDATE() AS DATE)		as RunDate,
				CycleStart					as StartFourWeek,
				CycleEnd					as EndFourWeek
	INTO		#DateRanges
	FROM		Warehouse.ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended
	WHERE		ID = @CycleIDRef
	
	-- SELECT * FROM #DateRanges

	---------------------------------------------------------------------------------
	-- Start retailer Loop
	---------------------------------------------------------------------------------

	SET @i = 1
	SET @NumBrands = (SELECT Max(ID) from #AllBrands)

	WHILE @i <= @NumBrands
		BEGIN
			-------------------------------------------------------------------------------------
			--  1. Identify the shopper segment
			-------------------------------------------------------------------------------------

			If Object_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
			Select              br.BrandID
								,br.BrandName
								,p.PartnerID
								,p.PartnerName
			Into                #Brand
			From				Relational.Brand br
			Left Join			Relational.Partner p on br.BrandID = p.BrandID
			Where               br.BrandID in (SELECT a.Brandid from #AllBrands a WHERE ID = @i)

			------------------------------------------
			-- a) Find the Acquire and Lapsed Length
			------------------------------------------

			If Object_ID('tempdb..#Settings') IS NOT NULL DROP TABLE #Settings
			Select		Distinct a.Brandname, b.BrandID, AcquireL, LapserL, SectorID
			Into        #Settings
			From		Warehouse.ExcelQuery.roceft_segment_lengths a
			INNER JOIN	#Brand b on a.BrandID = b.BrandID
			-- select * from #settings
				
			Declare		@Lapsed int
			Set			@Lapsed = (select LapserL from  #Settings) 

			Declare		@Acquire int
			Set			@Acquire = (select AcquireL from #Settings)

			Declare		@BrandName varchar(50)
			Set			@BrandName = (select BrandName from #Settings)

			Declare		@BrandID_Loop int
			Set			@BrandID_Loop = (select BrandID from #Settings)

			------------------------------------------
			-- b) Determine the time period needed
			------------------------------------------

			--select * from #DateRanges

			Declare		@startfutureperiod date
			Set			@startfutureperiod = (select StartFourWeek from #DateRanges)

			Declare		@endfutureperiod date
			Set			@endfutureperiod = (select EndFourWeek from #DateRanges)

			Declare		@starthistoricperiod date
			Set			@starthistoricperiod = (DATEADD(MONTH,-@Acquire,@startfutureperiod))

			Declare		@endhistoricperiod date
			Set			@endhistoricperiod = (SELECT DATEADD(DAY,-1,@startfutureperiod))

			Declare		@rundate date
			Set			@rundate = (select RunDate from #DateRanges)

			------------------------------------------
			-- c) Identify the base needed
			------------------------------------------

			If Object_ID('tempdb..#MyRewardsBase') IS NOT NULL DROP TABLE #MyRewardsBase
			Select top 1500000 *
			Into #MyRewardsBase
			From (
						Select		distinct cl.CINID
									,'MyRewards' as Segment
						From		Relational.Customer c
						Join		Relational.CINList cl on cl.cin = c.SourceUID                 
						Where		c.CurrentlyActive = 1
										and NOT EXISTS
													(              
													Select *
													From Staging.Customer_DuplicateSourceUID dup
													Where EndDate is null
													and        c.SourceUID = dup.SourceUID
													)
					) a
			order by newid()

			CREATE CLUSTERED INDEX ix_ccID on #MyRewardsBase(CINID)																			-- SELECT Count(*) FROM #MyRewardsBase


			-- Create list of customers that are on an offer in the evaluation period, so that they can be excluded, and thus not impact natural sales rates
			IF OBJECT_ID('Tempdb..#OnOffer') IS NOT NULL DROP TABLE #OnOffer
			select		distinct iom.CompositeID
						,cl.CINID
			INTO		#OnOffer
			from		Warehouse.Relational.IronOfferMember iom
			INNER JOIN	Warehouse.relational.customer c on iom.CompositeID = c.CompositeID
			INNER JOIN	Warehouse.Relational.Cinlist cl on cl.CIN = c.SourceUID
			INNER JOIN	Warehouse.Relational.IronOffer io on iom.IronOfferID = io.IronOfferID
			INNER JOIN	Warehouse.Relational.partner p on p.PartnerID = io.PartnerID
			INNER JOIN	#MyRewardsBase mrb on mrb.CINID = cl.CINID
			where		((
							io.StartDate <= @endfutureperiod
							AND (io.Enddate is Null OR io.EndDate >= @startfutureperiod)
						and	(iom.StartDate <= @endfutureperiod or iom.StartDate is null)
							AND (iom.Enddate is Null OR iom.EndDate >= @startfutureperiod)
							)
								OR io.EndDate IS NULL) 
						and BrandID = @BrandID_Loop	
											
			--  Select Count(*) from #Onoffer							

				
			DECLARE @PropOnOffer Float
			SET @PropOnOffer = (Select Count(distinct a.Cinid)
								FROM	#Onoffer a
								INNER JOIN #MyRewardsBase b on a.cinid = b.cinid)*1.0/
								(SELECT count(Distinct Cinid)
								FROM #MyRewardsBase)
				
			IF @PropOnOffer > 0.9
				BEGIN
					INSERT INTO #MyRewardsBase
						SELECT *
						FROM (	
								SELECT	Top 1500000 CINID
										,'MyRewards' as Segment
								FROM	Warehouse.APW.ControlAdjusted
								Order By NewID()
							) a
				END

				
			------------------------------------------
			-- d) Find consumer combination id's
			------------------------------------------

			IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC

			SELECT cc.BrandID
					,ConsumerCombinationID
			INTO   #CC
			FROM   Relational.ConsumerCombination cc
			JOIN   #Brand br ON br.BrandID=cc.BrandID

			CREATE CLUSTERED INDEX cix_BrandID_ConsumerCombinationID on #CC(BrandID,ConsumerCombinationID)

			------------------------------------------
			-- e) Historic spend
			------------------------------------------

			If Object_ID('tempdb..#HistoricData_1') IS NOT NULL DROP TABLE #HistoricData_1
			Select		ct.CINID
						,sum(ct.Amount) as Spend
						,count(1) as Frequency
						,max(ct.TranDate) as LastDate
			Into		#HistoricData_1
			From		Relational.ConsumerTransaction ct with (nolock)
			Join		#MyRewardsBase c on c.cinid=ct.cinid
			Join		#cc b on b.ConsumerCombinationID=ct.ConsumerCombinationID
			Where		ISRefund = 0 
						and trandate between @starthistoricperiod and @endhistoricperiod
			Group By	ct.CINID
							
			CREATE CLUSTERED INDEX ix_CINID on #HistoricData_1(CINID)										-- Select top 200 * from #HistoricData_1

			DECLARE @LapsedDate DATE = DATEADD(MONTH,-(@Lapsed),@EndHistoricPeriod)
			DECLARE @AcquireDate DATE = DATEADD(MONTH,-(@Acquire),@EndHistoricPeriod)
			
			IF OBJECT_ID('tempdb..#HistoricData_2') IS NOT NULL DROP TABLE #HistoricData_2
			SELECT		x.CINID
						,x.Segment
						,ISNULL(a.Frequency,0) as Frequency
						,a.LastDate
						,ISNULL(a.Spend,0) as Spend
						,ISNULL(DATEDIFF(DAY,LastDate,@endhistoricperiod),9999) AS recency_days
						,ISNULL(DATEDIFF(MONTH,LastDate,(@endhistoricperiod)),9999) AS recency_months
						,CASE
							WHEN @LapsedDate <= LastDate THEN 'Shopper'                                                              
							WHEN @AcquireDate <= LastDate THEN 'Lapsed' 
							ELSE 'Acquire' 
							END AS Shopper_Segment
			Into		#HistoricData_2
			From		#MyRewardsBase x
			Left outer join   #HistoricData_1 a on x.CINID = a.CINID

			CREATE CLUSTERED INDEX ix_CINID on #HistoricData_2(CINID)								-- Select top 200 * from #HistoricData_2 order by spend desc; Select sum(Spend) from #HistoricData_2

			IF OBJECT_ID('Tempdb..#NaturalSpend') IS NOT NULL DROP TABLE #NaturalSpend
			SELECT		ns.*
						,ch.Cardholders
			INTO		#NaturalSpend
			FROM		(SELECT		@BrandID_Loop as BrandID,
									Segment,
									Shopper_Segment,
									CASE WHEN c.CINID IS NULL THEN 'Natural'
										WHEN c.CINID IS NOT NULL THEN 'Incentivised'
										ELSE 'Error' 
									END AS IncentivisedYN,
									Sum(CASE WHEN IsOnline = 1 THEN Amount END) as OnlineSpend,
									Sum(Amount) as Spend,
									Count(*) as Transactions,
									Count(Distinct ct.Cinid) as Spenders
						FROM		Warehouse.relational.ConsumerTransaction ct with (Nolock) 
						INNER JOIN	#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID  
						INNER JOIN	#HistoricData_2 a on a.CINID = ct.CINID 
						LEFT JOIN	#OnOffer c on c.CINID = a.CINID
						WHERE		Trandate between @startfutureperiod and @endfutureperiod
									AND Amount > 0
						GROUP BY	Segment,
									Shopper_Segment,
									CASE WHEN c.CINID IS NULL THEN 'Natural'
											WHEN c.CINID IS NOT NULL THEN 'Incentivised'
										ELSE 'Error' END ) ns
			INNER JOIN	(SELECT           Shopper_Segment
                                                    ,case when b.cinid is not null then 'Incentivised' else 'Natural' end as IncentivisedYN
                                                    ,Count(*) as cardholders
                                FROM        #HistoricData_2 a
                                left join    #OnOffer b on a.cinid = b.cinid
                                GROUP BY    Shopper_Segment
                                                    ,case when b.cinid is not null then 'Incentivised' else 'Natural' end) ch on ch.Shopper_Segment = ns.Shopper_Segment and ch.IncentivisedYN = ns.IncentivisedYN 
										
																			-- Select * from #NaturalSpend 
																

			--  Section to determine if this retailer/Segment has low spend in the evaluation period.  If so, use an average from BrandSpend Report data, scale to ave segment proportions
			
			IF OBJECT_ID('Tempdb..#LowSegments') IS NOT NULL DROP TABLE #LowSegments
			SELECT		b.Shopper_Segment,
						isnull(Sum(Transactions),0) as txns
			INTO		#LowSegments
			FROM		(Select * from #NaturalSpend WHERE IncentivisedYN = 'Natural') a
			RIGHT JOIN (SELECT 'Acquire' as Shopper_Segment
						UNION
						SELECT 'Lapsed'
						UNION
						SELECT 'Shopper') b on a.Shopper_Segment = b.Shopper_Segment
			GROUP BY	b.Shopper_Segment
			HAVING     isnull(Sum(Transactions),0) <50																-- SELECT * from #LowSegments
																					
			DELETE FROM #NaturalSpend WHERE Shopper_Segment IN (Select Shopper_Segment FROM #LowSegments) and IncentivisedYN = 'Natural'

			IF OBJECT_ID('Tempdb..#ShopperSegmentScaling') IS NOT NULL DROP TABLE #ShopperSegmentScaling
			CREATE TABLE #ShopperSegmentScaling
				(
					ShopperSegment Varchar(max),
					PercSpend Float,
					PercTransactions Float,
					PercSpenders Float,
					PercCardholders Float
				)


			IF OBJECT_ID('Tempdb..#ShopperSegmentSummary') IS NOT NULL DROP TABLE #ShopperSegmentSummary
			SELECT		Shopper_Segment,
						Sum(Spend) as Spend,
						Sum(Transactions) as Transactions,
						Sum(Spenders) as Spenders,
						Sum(Cardholders) as Cardholders
			INTO		#ShopperSegmentSummary
			FROM		Warehouse.InsightArchive.ROCEFT_NaturalSpend_Backup
			GROUP BY	Shopper_Segment


			INSERT INTO #ShopperSegmentScaling
				SELECT		distinct Shopper_Segment,
							sum(Spend*1.0) over(Partition by  Shopper_Segment)/Sum(Spend) OVER () as PercSpend,
							sum(Transactions*1.0) over(Partition by  Shopper_Segment)/Sum(Transactions) OVER () as PercTransactions,
							sum(Cardholders*1.0) over(Partition by  Shopper_Segment)/Sum(Cardholders) OVER () as PercSpenders,
							sum(Cardholders*1.0) over(Partition by  Shopper_Segment)/Sum(Cardholders) OVER () as PercCardholders
				FROM		#ShopperSegmentSummary																									-- SELECT * FROM #ShopperSegmentScaling

			INSERT INTO #NaturalSpend
				SELECT		@BrandID_Loop,
							'MyRewards' as Segment,
							ShopperSegment,
							'Natural' as IncentivisedYN,
							OnlineSpendThisYear*PercSpend/13 as OnlineSpend_Scaled,
							SpendThisYear*PercSpend/13 as Spend_Scaled,
							TranCountThisYear*PercTransactions/13 as Transactions_Scaled,
							CustomerCountThisYear*PercSpenders/13 as Spenders_Scaled,
							TotalCustomerCountThisYear*PercCardholders/13 as Cardholders_Scaled							
				FROM		warehouse.mi.TotalBrandSpend_CBP 
				CROSS JOIN  warehouse.mi.GrandTotalCustomers_CBP 
				CROSS JOIN	#ShopperSegmentScaling b
				INNER JOIN	#LowSegments c on b.ShopperSegment = c.Shopper_Segment
				WHERE		BrandID = @BrandID_Loop
				
			INSERT INTO Warehouse.ExcelQuery.ROCEFT_NaturalSpend							--SELECT * from Warehouse.ExcelQuery.ROCEFT_NaturalSpend
				SELECT	@CycleIDRef,
						a.BrandID,
						a.Segment,
						a.Shopper_Segment,
						a.IncentivisedYN,
						a.Spend,
						a.Transactions,
						a.Spenders,
						a.cardholders,
						Spenders*1.0/Cardholders,
						Spend/Cardholders,
						Spend/nullif(Spenders,0),
						Spend/nullif(Transactions,0),
						Transactions*1.0/nullif(Spenders,0),
						Transactions*1.0/Cardholders,
						OnlineSpend*1.0/nullif(Spend,0)
				FROM	#NaturalSpend a
				WHERE	IncentivisedYN = 'Natural'

			INSERT INTO Warehouse.ExcelQuery.ROCEFT_IncentivisedSpend						--SELECT top 200 * from Warehouse.ExcelQuery.ROCEFT_IncentivisedSpend
				SELECT	@CycleIDRef,
						a.BrandID,
						a.Segment,
						a.Shopper_Segment,
						a.IncentivisedYN,
						a.Spend,
						a.Transactions,
						a.Spenders,
						a.cardholders,
						Spenders*1.0/Cardholders,
						Spend/Cardholders,
						Spend/nullif(Spenders,0),
						Spend/nullif(Transactions,0),
						Transactions*1.0/nullif(Spenders,0),
						Transactions*1.0/Cardholders
				FROM	#NaturalSpend a
				WHERE	IncentivisedYN = 'Incentivised'
				
				SET @i = @i + 1
		END
END
