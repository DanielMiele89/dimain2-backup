-- ===================================================================================
-- Author:		<Shaun Hide>
-- Create date: <19/05/2017>
-- Description:	<Decay Rate Calculations for Shopper => Lapsed, and Lapsed => Acquire>
-- Update: Shaun - Efficiency changes / Improvements 29/06/2017
-- ===================================================================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_DecayRate]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Declare @time DATETIME
	Declare @msg VARCHAR(2048)

	SELECT @msg = 'Start'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	---------------------------------------------------------------------------------------------
	-- Find a random 1.5m sample (Needs to be fixed so that churn is real)
	IF OBJECT_ID('Warehouse.Prototype.RandomBase') IS NOT NULL DROP TABLE Warehouse.Prototype.RandomBase
	Select	top 1500000 CINID
	Into	Warehouse.Prototype.RandomBase
	From	Warehouse.InsightArchive.WETSFixedBase
	Order by newid()

	CREATE CLUSTERED INDEX ix_CINID ON Warehouse.Prototype.RandomBase(CINID)

	---------------------------------------------------------------------------------------------
	-- Generate date table
	
	Declare @Today		Date = GETDATE() - 7													-- Arbitrary 7 days prior to ensure we will have data
	Declare	@ReportDate	Date = DATEADD(DAY,-(DATEDIFF(DAY,'2016-04-28',@Today)%28 + 1),@Today)  -- Finds the last report date prior to GETDATE() - 7 

	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
	CREATE TABLE #Dates
		(
			StartDate	Date
			,EndDate	Date
			,DateRange	Int
		)

	INSERT INTO #Dates
		SELECT DATEADD(DAY,-111,@ReportDate),DATEADD(DAY,-84,@ReportDate),1
	INSERT INTO #Dates
		SELECT DATEADD(DAY,-83,@ReportDate),DATEADD(DAY,-56,@ReportDate),2
	INSERT INTO	#Dates
		SELECT DATEADD(DAY,-55,@ReportDate),DATEADD(DAY,-28,@ReportDate),3
	INSERT INTO #Dates
		SELECT DATEADD(DAY,-27,@ReportDate),@ReportDate,4

	--Select * From #Dates

	Declare @BrandID int, @RowNo int, @Acquire Int, @Lapsed Int
	Declare @LapsedAcquire Decimal(12,11), @ShopperLapsed Decimal(12,11)

	-- ALS Assignment Stored Procedure Setup
	Declare @PopulationTable varchar(100) = 'Warehouse.Prototype.RandomBase'
	Declare @SegmentDate Date = (Select DATEADD(DAY,-1,StartDate) From #Dates Where DateRange = 1) 

	SELECT @msg = 'Entering Loop'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	SET @rowno=1
	WHILE @RowNo <= (select max(rowno) From Warehouse.ExcelQuery.ROCEFT_RefreshBrand)
		BEGIN
			
			----------------------------------------------------------------------------------
			-- Derive all the needed brand features
			----------------------------------------------------------------------------------

			------------------------------------------------
			-- Create the single brand table (for joins etc)					
			IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
			Select	*
			Into	#Brand
			From	Warehouse.ExcelQuery.ROCEFT_RefreshBrand
			Where	RowNo = @RowNo

			SET @BrandID = (Select BrandID From #Brand Where RowNo = @RowNo)

			SELECT @msg = 'Running RowNo' + cast(@RowNo as varchar(10)) + ' which is BrandID ' + cast(@BrandID as varchar(10))
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
			
			-------------------------------------------------------------
			-- Find the ConsumerCombinationIDs associated with this brand
			IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
			Select	distinct ConsumerCombinationID
			Into	#CC
			From	Warehouse.Relational.ConsumerCombination 
			Where	BrandID = @BrandID
				and IsUKSpend = 1

			CREATE CLUSTERED INDEX ix_ConsumerCombinationID ON #CC(ConsumerCombinationID)

			-------------------------------------------------
			-- Define Acquire / Lapsed Lengths for this Brand
			IF OBJECT_ID('tempdb..#Settings') IS NOT NULL DROP TABLE #Settings
			Select	distinct br.BrandName
					,br.BrandID
					,coalesce(mrf.SS_AcquireLength,blk.acquireL,lk.AcquireL,br.AcquireL0) as AcquireL
					,coalesce(mrf.SS_LapsersDefinition,blk.LapserL,lk.LapserL,br.LapserL0) as LapserL
					,br.SectorID
			Into	#Settings
			From	(
						Select	distinct BrandID
								,BrandName
								,SectorID
								,case when BrandName in ('Tesco','Asda','Sainsburys','Morrisons') then 3 end as AcquireL0
								,case when BrandName in ('Tesco','Asda','Sainsburys','Morrisons') then 1 end as LapserL0
						From	Warehouse.Relational.Brand
					) br
			Left Join	Warehouse.Relational.Partner p on p.BrandID = br.BrandID
			Left Join	Warehouse.Relational.MRF_ShopperSegmentDetails mrf on mrf.PartnerID = p.PartnerID
			Left Join	Warehouse.Prototype.ROCP2_SegFore_BrandTimeFrame_LK blk on br.BrandID = blk.BrandID
			Left Join	Warehouse.Prototype.ROCP2_SegFore_SectorTimeFrame_LK lk on br.SectorID = lk.SectorID
			Where		coalesce(mrf.SS_AcquireLength,blk.acquireL,lk.AcquireL,br.AcquireL0) is not null
					and	br.BrandID = @BrandID
			
			Set @Lapsed = (Select min(LapserL) From #Settings)
			Set @Acquire = (Select min(AcquireL) From #Settings)

			----------------------------------------------------------------------------------
			-- Perform the segment assignment for the X periods
			----------------------------------------------------------------------------------

			--SELECT @msg = 'Segment Assignment - Begin'
			--EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
			-----------------------------
			-- Initial Segment Assignment
			IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
			CREATE TABLE #SegmentAssignment
				(
					CINID	Int
					,Segment VarChar(20)
					,LastTran Date
				)

			INSERT INTO #SegmentAssignment
				EXEC Warehouse.Prototype.SegmentAssignment @BrandID, @PopulationTable, @SegmentDate

			------------------------------------------------------
			-- Create the table needed to produce the output table
			IF OBJECT_ID('tempdb..#SegmentsByFourWeeks') IS NOT NULL DROP TABLE #SegmentsByFourWeeks
			CREATE TABLE #SegmentsByFourWeeks 
				(
					DateRange Int
					,CINID Int
					,Segment VarChar(20)
					,LastTran Date
				)

			INSERT INTO #SegmentsByFourWeeks
				Select	1 as DateRange
						,a.CINID
						,a.Segment
						,a.LastTran
				From	#SegmentAssignment a
			
			----------------------------------------------------------------
			-- Loop through each period (updating the segments as necessary)

			Declare @StartDate Date, @EndDate Date, @LapsedDate Date, @AcquireDate Date
			Declare @DateRange Int = 2

			-- LOOP START HERE
			WHILE @DateRange <= (Select max(DateRange) From #Dates)
				BEGIN
					SELECT @msg = 'Segment Change Loop :' + cast((@DateRange - 1) as varchar(10))
					EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

					Set @StartDate =	(Select StartDate From #Dates Where DateRange = @DateRange)
					Set @EndDate =		(Select EndDate From #Dates Where DateRange = @DateRange)
					Set @LapsedDate =	DATEADD(MONTH,-@Lapsed,@EndDate)
					Set @AcquireDate =  DATEADD(MONTH,-@Acquire,@EndDate)

					-- Create a temporary segment assignment (to be updated)
					IF OBJECT_ID('tempdb..#TempSegment') IS NOT NULL DROP TABLE #TempSegment
					Select	*
					Into	#TempSegment
					From	#SegmentsByFourWeeks
					Where	DateRange = (@DateRange - 1)

					CREATE CLUSTERED INDEX ix_CINID ON #TempSegment(CINID)

					-- Find Purchasers
					IF OBJECT_ID('tempdb..#Purchasers') IS NOT NULL DROP TABLE #Purchasers
					Select	ct.CINID
							,max(ct.TranDate) as LastTran
					Into	#Purchasers
					From	Warehouse.Relational.ConsumerTransaction ct with (nolock)
					Join	Warehouse.Prototype.RandomBase pop on ct.CINID = pop.CINID
					Join	#CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
					Where	@StartDate <= ct.TranDate and ct.TranDate <= @EndDate
					Group By ct.CINID

					CREATE CLUSTERED INDEX ix_CINID ON #Purchasers(CINID)

					-- UPDATE: Acquire -> Shopper AND Lapsed -> Shopper
					--Print ' Updating Acquires -> Shoppers, and Lapsed to Shoppers'
					UPDATE	seg
					SET		seg.Segment = 'Shopper'
						, seg.DateRange = @DateRange
						, seg.LastTran = p.LastTran
					FROM	#TempSegment seg
					JOIN	#Purchasers p
						ON	seg.CINID = p.CINID

					-- Shopper -> Lapsed
					--Print ' Updating Shoppers -> Lapsed and Lapsed -> Lapsed'
					UPDATE	seg
					SET		seg.Segment = 'Lapsed'
							,seg.DateRange = @DateRange
					FROM	#TempSegment seg
					WHERE	DateRange <> @DateRange
						and	@AcquireDate <= LastTran 
						and	LastTran < @LapsedDate
			
					-- Lapsed -> Acquire
					--Print ' Updating Lapsed -> Acquire and Acquire -> Acquire'
					UPDATE	seg
					SET		seg.Segment = 'Acquire'
							,seg.DateRange = @DateRange
					FROM	#TempSegment seg
					WHERE	DateRange <> @DateRange
						and	LastTran < @AcquireDate or LastTran IS NULL

					-- Shopper -> Shopper
					--Print ' Updating Shopper -> Shopper'
					UPDATE	seg
					SET		seg.DateRange = @DateRange
					FROM	#TempSegment seg
					WHERE	DateRange <> @DateRange
						and	@LapsedDate <= LastTran 
			
					INSERT INTO #SegmentsByFourWeeks
						SELECT	*
						FROM	#TempSegment

					OPTION (RECOMPILE)

					Set @DateRange = @DateRange + 1
			END
			
			IF OBJECT_ID('tempdb..#Lagged') IS NOT NULL DROP TABLE #Lagged
			Select	*
					,Segment1 = LAG(Segment, 1) OVER (PARTITION BY CINID ORDER BY DateRange)
			Into	#Lagged
			From	#SegmentsByFourWeeks

			IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output
			Select	a.DateRange
					,a.Segment1
					,a.Segment
					,coalesce(1.0*a.Shoppers/nullif(b.Shoppers,0),0) as DecayRate
			Into	#Output
			From	(
						Select	DateRange
								,Segment1
								,Segment
								,count(distinct CINID) as Shoppers
						From	#Lagged
						Where	(Segment1 = 'Lapsed' and Segment = 'Acquire')
							or	(Segment1 = 'Shopper' and Segment = 'Lapsed')
						Group By DateRange
								,Segment1
								,Segment
					) a
			Join	(
						Select	DateRange
								,Segment1
								,count(distinct CINID) as Shoppers
						From	#Lagged
						Group By DateRange
								,Segment1
					) b on a.DateRange = b.DateRange and a.Segment1 = b.Segment1
			
			SET @LapsedAcquire = (SELECT CAST(AVG(DecayRate) as Decimal(12,11)) From #Output Where Segment1 = 'Lapsed' and Segment = 'Acquire')
			SET @ShopperLapsed = (SELECT CAST(AVG(DecayRate) as Decimal(12,11)) From #Output Where Segment1 = 'Shopper' and Segment = 'Lapsed')

			INSERT INTO Warehouse.ExcelQuery.ROCEFT_DecayRates
				Select	@BrandID
						,@LapsedAcquire
						,@ShopperLapsed

			OPTION (RECOMPILE)

			SELECT @msg = 'End Loop'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			SET @RowNo = @RowNo + 1
		END
END
