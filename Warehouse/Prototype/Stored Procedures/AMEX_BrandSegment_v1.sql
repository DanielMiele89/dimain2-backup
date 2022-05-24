-- =================================================================================
-- Author:		<Shaun Hide>
-- Create date: <30th March 2017>
-- Description:	<Brand Segment Running - ALS Splits and Data>
-- =================================================================================
CREATE PROCEDURE [Prototype].[AMEX_BrandSegment_v1]
AS
BEGIN
	SET NOCOUNT ON;

	Declare @time DATETIME
	Declare @msg VARCHAR(2048)

	SELECT @msg = 'Start - Brand Segment'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------------------------
	--	Specify Dates
	-------------------------------------------------------------------------------------

	Declare		@startdate date
	Set			@startdate = (select StartDate from Warehouse.Prototype.AMEX_Dates)

	Declare		@enddate date
	Set			@enddate = (select EndDate from Warehouse.Prototype.AMEX_Dates)

	-------------------------------------------------------------------------------------
	--	Derive shopper (used across all brands) for 1.5m sample
	-------------------------------------------------------------------------------------

	-- Select 1.5m sample
	If Object_ID('tempdb..#MyRewardsBase') IS NOT NULL DROP TABLE #MyRewardsBase
	Select top 1500000 *
	Into #MyRewardsBase
	From (
			Select distinct cl.CINID
							,'My Rewards' as Segment
			From			Relational.Customer c
			Join			Relational.CINList cl 
						 on cl.cin = c.SourceUID		
			Where			c.CurrentlyActive = 1
				and NOT EXISTS
						(	
						Select	*
						From	Staging.Customer_DuplicateSourceUID dup
						Where	EndDate is null
							and	c.SourceUID = dup.SourceUID
						)
		  ) a
	order by newid()

	CREATE CLUSTERED INDEX ix_ccID on #MyRewardsBase(CINID)

	SELECT @msg = 'Dates and Customers Determined'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-- Loop Here

	DECLARE @rowno int
	Set @rowno=1

	WHILE @rowno  <= (select max(rowno) from Warehouse.Prototype.AMEX_RefreshBrand)        
		BEGIN
			SELECT @msg = 'RowNo ' + cast(@RowNo as varchar(3))
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
			---------------------------------------------------------------------------------------------
			-- Create a single brand brand table

			IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
			Select	*
			Into	#Brand
			From	Warehouse.Prototype.AMEX_RefreshBrand
			Where	RowNo = @RowNo

			-- select * from #Brand

			---------------------------------------------------------------------------------------------
			-- Identify the relevant Acquire and Lasped length
				
			If Object_ID('tempdb..#MasterRetailerFile') IS NOT NULL DROP TABLE #MasterRetailerFile
			Select	br.BrandID
					,br.BrandName
					,mrf.[SS_AcquireLength]
					,mrf.[SS_LapsersDefinition]
					,mrf.[SS_WelcomeEmail]
					,cast(SS_Acq_Split*100 as int) as Acquire_Pct
			Into	#MasterRetailerFile 
			From	Relational.MRF_ShopperSegmentDetails mrf
			Join	Relational.Partner p 
				on	mrf.PartnerID = p.PartnerID
			Join	#Brand br
				 on p.BrandID = br.BrandID
		
			-- select * from #MasterRetailerFile

			If Object_ID('tempdb..#Settings') IS NOT NULL DROP TABLE #Settings
			Select distinct		a.BrandName
								,a.BrandID
								,coalesce(mrf.SS_AcquireLength,blk.acquireL,a.AcquireL0) as AcquireL
								,coalesce(mrf.SS_LapsersDefinition,blk.LapserL,a.LapserL0) as LapserL
								,a.sectorID
			Into				#Settings
			From	(
						Select		b.BrandID
									,b.BrandName
									,b.sectorID
									,case when b.BrandName in ('Tesco', 'Asda','Sainsburys','Morrisons') then 3 else lk.acquireL end as AcquireL0
									,case when b.BrandName in ('Tesco', 'Asda','Sainsburys','Morrisons') then 1 else lk.LapserL end as LapserL0
									,lk.Acquire_Pct as Acquire_Pct0
						From		Relational.Brand b
						Join		#Brand br
								on  b.BrandID = br.BrandID
						Left Join	Warehouse.Prototype.ROCP2_SegFore_SectorTimeFrame_LK lk 
								on	lk.sectorid=b.sectorID
					) a
			Left Join			Prototype.ROCP2_SegFore_BrandTimeFrame_LK blk 
							on	blk.brandid=a.brandID
			Left Join			#MasterRetailerFile mrf 
							on	mrf.BrandID = a.BrandID
			Where			coalesce(mrf.SS_AcquireLength,blk.acquireL,AcquireL0) is not null
		
			-- select * from #Settings

			Declare		@Lapsed int
			Set			@Lapsed = (SELECT CASE WHEN 6 < LapserL THEN 6 ELSE LapserL END FROM #Settings)		-- AMEX can only have a maximum of 12 months worth of data

			Declare		@Acquire int
			Set			@Acquire = (SELECT CASE WHEN 12 < AcquireL THEN 12 ELSE AcquireL END FROM #Settings) -- AMEX can only have a maximum of 12 months worth of data

			Declare		@BrandName varchar(50)
			Set			@BrandName = (select BrandName from #Settings)

			Declare		@BrandID smallint
			Set			@BrandID= (select BrandID from #Settings)

			Declare		@starthistoricperiod date
			Set			@starthistoricperiod = (dateadd(month,-@Acquire,dateadd(day,1,@startdate)))

			-- Deal with weird brand IDs
			IF (Select count(*) From #Settings) = 0
				BEGIN
					Insert Into Warehouse.Prototype.AMEX_RunIssues
						Select		@BrandID
									,@BrandName
									,'This brand does not have any ALS details...'
					Set @rowno = @rowno + 1
					CONTINUE
				END

			--SELECT @msg = 'Acquire/Lapsed Length determined'
			--EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			---------------------------------------------------------------------------------------------
			-- Identify the relevant consumer combination IDs
		
			If Object_ID('tempdb..#cc') IS NOT NULL DROP TABLE #cc
			Select	cc.brandid
					,ConsumerCombinationID
			Into	#cc
			From	Relational.ConsumerCombination cc
			Join	#Brand br on br.BrandID=cc.BrandID

			CREATE CLUSTERED INDEX ix_brandID on #cc(BrandID)
			CREATE NONCLUSTERED INDEX ix_ccID on #cc(ConsumerCombinationID)

			--SELECT @msg = 'Relevant consumer combinations determined'
			--EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			---------------------------------------------------------------------------------------------
			-- Historic spend 
		
			If Object_ID('tempdb..#HistoricSpend') IS NOT NULL DROP TABLE #HistoricSpend
			Select		ct.CINID
						,sum(ct.Amount) as Spend
						,count(1) as Frequency
						,max(ct.TranDate) as LastDate
			Into		#HistoricSpend
			From		Relational.ConsumerTransaction ct with (nolock)
			Join		#MyRewardsBase c on c.cinid=ct.cinid
			Join		#cc b on b.ConsumerCombinationID=ct.ConsumerCombinationID
			Where		ISRefund = 0 
					and trandate between @starthistoricperiod and @startdate
			Group By	ct.CINID

			CREATE CLUSTERED INDEX ix_CINID on #HistoricSpend(CINID)

			--SELECT @msg = 'Historic spend data for brand found'
			--EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			---------------------------------------------------------------------------------------------
			-- Segment assignment

			If Object_ID('tempdb..#Segments') IS NOT NULL DROP TABLE #Segments
			Select		a.*
						,case 
							when isnull(DATEDIFF(MONTH,LastDate,(@startdate)),9999) <= @Lapsed then 'Shopper'				
							when isnull(DATEDIFF(MONTH,LastDate,(@startdate)),9999) <= @Acquire then 'Lapsed' else 'Acquire' 
							end as Shopper_Segment
			Into		#Segments
			From		#MyRewardsBase a
			Left Join	#HistoricSpend hist on	a.CINID = hist.CINID		

			CREATE CLUSTERED INDEX ix_CINID on #Segments(CINID)

			-- Flag Segment issues
			IF (Select count(distinct Shopper_Segment) From #Segments) < 3
				BEGIN
					Insert Into Warehouse.Prototype.AMEX_RunIssues
						Select		@BrandID
									,@BrandName
									,'This brand does not have all three segments (investigate)...'
					Set @rowno = @rowno + 1
					CONTINUE
				END
			--SELECT @msg = 'Segment Assignment'
			--EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			---------------------------------------------------------------------------------------------
			-- Brand - Segment Metrics

			Declare @TotalBase Int
			Set @TotalBase = (select count(distinct CINID) from #Segments)

			If Object_ID('tempdb..#ToplineBrandSeg') IS NOT NULL DROP TABLE #ToplineBrandSeg
			Select		@BrandID as BrandID
						,@BrandName	as BrandName
						,'Total' as Segment
						,@TotalBase	as Base
						,sum(ct.Amount)	as Brand_Spend
						,count(1) as Brand_Trans
						,count(distinct ct.CINID) as Brand_Spenders

						,coalesce(1.0*sum(ct.Amount)/nullif(count(1),0),0) as Brand_ATV
						,coalesce(1.0*count(1)/nullif(count(distinct ct.CINID),0),0) as Brand_ATF
						,coalesce(1.0*sum(ct.Amount)/nullif(count(distinct ct.CINID),0),0) as Brand_SPS
						,coalesce(1.0*count(distinct ct.CINID)/nullif(@TotalBase,0),0) as Brand_RR

						,sum(case when IsOnline = 0 then ct.Amount else 0 end) as InStore_Brand_Spend
						,count(case when IsOnline = 0 then 1 else NULL end) as InStore_Brand_Trans
						,count(distinct case when IsOnline = 0 then ct.CINID else NULL end) as InStore_Brand_Spenders

						,coalesce(1.0*sum(case when IsOnline = 0 then ct.Amount else 0 end)/nullif(count(case when IsOnline = 0 then 1 else NULL end),0),0) as InStore_Brand_ATV
						,coalesce(1.0*count(case when IsOnline = 0 then 1 else NULL end)/nullif(count(distinct case when IsOnline = 0 then ct.CINID else NULL end),0),0) as InStore_Brand_ATF
						,coalesce(1.0*sum(case when IsOnline = 0 then ct.Amount else 0 end)/nullif(count(distinct case when IsOnline = 0 then ct.CINID else NULL end),0),0) as InStore_Brand_SPS
						,coalesce(1.0*count(distinct case when IsOnline = 0 then ct.CINID else NULL end)/nullif(@TotalBase,0),0) as InStore_Brand_RR

			Into		#ToplineBrandSeg
			From		Relational.ConsumerTransaction ct with (nolock)
			Join		#Segments seg on seg.cinid=ct.cinid
			Join		#cc b on b.ConsumerCombinationID=ct.ConsumerCombinationID
			Where		ISRefund = 0 
					and trandate between @startdate and @enddate

			-- select * from #ToplineBrandSeg

			If Object_ID('tempdb..#BrandSegmentMetrics') IS NOT NULL DROP TABLE #BrandSegmentMetrics
			Select		@BrandID as BrandID
						,@BrandName as BrandName
						,seg.Shopper_Segment as Segment
						,c.SegBase as Base
						,sum(ct.Amount)	as Brand_Spend
						,count(1) as Brand_Trans
						,count(distinct ct.CINID) as Brand_Spenders

						,coalesce(1.0*sum(ct.Amount)/nullif(count(1),0),0) as Brand_ATV
						,coalesce(1.0*count(1)/nullif(count(distinct ct.CINID),0),0) as Brand_ATF
						,coalesce(1.0*sum(ct.Amount)/nullif(count(distinct ct.CINID),0),0) as Brand_SPS
						,coalesce(1.0*count(distinct ct.CINID)/nullif(c.SegBase,0),0) as Brand_RR

						,sum(case when IsOnline = 0 then ct.Amount else 0 end) as InStore_Brand_Spend
						,count(case when IsOnline = 0 then 1 else NULL end) as InStore_Brand_Trans
						,count(distinct case when IsOnline = 0 then ct.CINID else NULL end) as InStore_Brand_Spenders

						,coalesce(1.0*sum(case when IsOnline = 0 then ct.Amount else 0 end)/nullif(count(case when IsOnline = 0 then 1 else NULL end),0),0) as InStore_Brand_ATV
						,coalesce(1.0*count(case when IsOnline = 0 then 1 else NULL end)/nullif(count(distinct case when IsOnline = 0 then ct.CINID else NULL end),0),0) as InStore_Brand_ATF
						,coalesce(1.0*sum(case when IsOnline = 0 then ct.Amount else 0 end)/nullif(count(distinct case when IsOnline = 0 then ct.CINID else NULL end),0),0) as InStore_Brand_SPS
						,coalesce(1.0*count(distinct case when IsOnline = 0 then ct.CINID else NULL end)/nullif(c.SegBase,0),0) as InStore_Brand_RR

			Into		#BrandSegmentMetrics
			From		Relational.ConsumerTransaction ct with (nolock)
			Join		#Segments seg on seg.cinid=ct.cinid
			Join		#cc b on b.ConsumerCombinationID=ct.ConsumerCombinationID
			Join		(
							Select	Shopper_Segment
									,count(distinct CINID) as SegBase
							From	#Segments
							Group By Shopper_Segment
						) c on c.Shopper_Segment = seg.Shopper_Segment
			Where		ISRefund = 0 
					and trandate between @startdate and @enddate
			Group By	seg.Shopper_Segment
						,c.SegBase

			-- select * from #BrandSegmentMetrics

			--SELECT @msg = 'Brand & Segment metrics determined'
			--EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			---------------------------------------------------------------------------------------------
			-- Brand Sector - Segment Metrics (Using Retailer ALS groups)
		
			If Object_ID('tempdb..#cc_sec') IS NOT NULL DROP TABLE #cc_sec
			Select		@BrandID as BrandID
						,ConsumerCombinationID
			Into		#cc_sec
			From		Warehouse.Relational.ConsumerCombination cc
			Join		Warehouse.Relational.Brand br
					on	br.BrandID = cc.BrandID
			Join		#Settings sec 
					on sec.SectorID = br.SectorID
			
			-- select * From #cc_sec
			If Object_ID('tempdb..#ToplineSector') IS NOT NULL DROP TABLE #ToplineSector
			Select		@BrandID as BrandID
						,@BrandName	as BrandName
						,'Total' as Segment
						,@TotalBase	as Base
						,sum(ct.Amount)	as Sector_Spend
						,count(1) as Sector_Trans
						,count(distinct ct.CINID) as Sector_Spenders
						,1.0*sum(ct.Amount)/count(1) as Sector_ATV
						,1.0*count(1)/count(distinct ct.CINID) as Sector_ATF
						,1.0*sum(ct.Amount)/count(distinct ct.CINID) as Sector_SPS
						,1.0*count(distinct ct.CINID)/@TotalBase as Sector_RR
			Into		#ToplineSector
			From		Warehouse.Relational.ConsumerTransaction ct with (nolock)
			Join		#cc_sec cc on ct.ConsumerCombinationID = cc.ConsumerCombinationID
			Join		#Segments seg on seg.cinid=ct.cinid
			Where		ISRefund = 0 
					and trandate between @startdate and @enddate

			If Object_ID('tempdb..#SectorSegmentMetrics') IS NOT NULL DROP TABLE #SectorSegmentMetrics
			Select		@BrandID as BrandID
						,@BrandName as BrandName
						,seg.Shopper_Segment as Segment
						,c.SegBase as Base
						,sum(ct.Amount)	as Sector_Spend
						,count(1) as Sector_Trans
						,count(distinct ct.CINID) as Sector_Spenders
						,1.0*sum(ct.Amount)/count(1) as Sector_ATV
						,1.0*count(1)/count(distinct ct.CINID) as Sector_ATF
						,1.0*sum(ct.Amount)/count(distinct ct.CINID) as Sector_SPS
						,1.0*count(distinct ct.CINID)/c.SegBase as Sector_RR
			Into		#SectorSegmentMetrics
			From		Relational.ConsumerTransaction ct with (nolock)
			Join		#Segments seg on seg.cinid=ct.cinid
			Join		#cc_sec b on b.ConsumerCombinationID=ct.ConsumerCombinationID
			Join		(
							Select	Shopper_Segment
									,count(distinct CINID) as SegBase
							From	#Segments
							Group By Shopper_Segment
						) c on c.Shopper_Segment = seg.Shopper_Segment
			Where		ISRefund = 0 
					and trandate between @startdate and @enddate
			Group By	seg.Shopper_Segment
						,c.SegBase

			--SELECT @msg = 'Sector & Segment metrics determined'
			--EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
		
			Insert Into	Warehouse.Prototype.AMEX_BrandSegment
				Select	*
				From	(
							(Select a.BrandID
									,a.BrandName
									,a.Segment
									,a.Base
									,a.Brand_Spend
									,a.Brand_Trans
									,a.Brand_Spenders
									,a.Brand_ATV
									,a.Brand_ATF
									,a.Brand_SPS
									,a.Brand_RR
									,b.Sector_Spend
									,b.Sector_Trans
									,b.Sector_Spenders
									,b.Sector_ATV
									,b.Sector_ATF
									,b.Sector_SPS
									,b.Sector_RR
									,a.InStore_Brand_Spend
									,a.InStore_Brand_Trans
									,a.InStore_Brand_Spenders
									,a.InStore_Brand_ATV
									,a.InStore_Brand_ATF
									,a.InStore_Brand_SPS
									,a.InStore_Brand_RR
								From	#ToplineBrandSeg a
								Join	#ToplineSector b
								on		a.BrandID = b.BrandID
								and	a.Segment = b.Segment)
							union
							(Select a.BrandID
									,a.BrandName
									,a.Segment
									,a.Base
									,a.Brand_Spend
									,a.Brand_Trans
									,a.Brand_Spenders
									,a.Brand_ATV
									,a.Brand_ATF
									,a.Brand_SPS
									,a.Brand_RR
									,b.Sector_Spend
									,b.Sector_Trans
									,b.Sector_Spenders
									,b.Sector_ATV
									,b.Sector_ATF
									,b.Sector_SPS
									,b.Sector_RR
									,a.InStore_Brand_Spend
									,a.InStore_Brand_Trans
									,a.InStore_Brand_Spenders
									,a.InStore_Brand_ATV
									,a.InStore_Brand_ATF
									,a.InStore_Brand_SPS
									,a.InStore_Brand_RR
								From #BrandSegmentMetrics a 
								Join	#SectorSegmentMetrics b
								on		a.BrandID = b.BrandID
								and	a.Segment = b.Segment)
						) e

			OPTION (RECOMPILE)
			Set @rowno = @rowno +1
		END

	SELECT @msg = 'End - Brand Segment'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------------------------
	--							X. Code Graveyard 
	-------------------------------------------------------------------------------------
	--IF OBJECT_ID('Warehouse.Prototype.AMEX_BrandSegment') IS NOT NULL DROP TABLE Warehouse.Prototype.AMEX_BrandSegment
	--CREATE TABLE Warehouse.Prototype.AMEX_BrandSegment
	--		(
	--			BrandID						smallint
	--			,BrandName					varchar(50)
	--			,Segment					varchar(50)
	--			,Base						int
	--			,Brand_Spend				money
	--			,Brand_Trans				int
	--			,Brand_Spenders				int
	--			,Brand_ATV					numeric(33,16)
	--			,Brand_ATF					numeric(33,16)
	--			,Brand_SPS					numeric(33,16)
	--			,Brand_RR					numeric(33,16)
	--			,Sector_Spend				money
	--			,Sector_Trans				int
	--			,Sector_Spenders			int
	--			,Sector_ATV					numeric(33,16)
	--			,Sector_ATF					numeric(33,16)
	--			,Sector_SPS					numeric(33,16)
	--			,Sector_RR					numeric(33,16)
	--			,InStore_Brand_Spend		money
	--			,InStore_Brand_Trans		int
	--			,InStore_Brand_Spenders		int
	--			,InStore_Brand_ATV			numeric(33,16)
	--			,InStore_Brand_ATF			numeric(33,16)
	--			,InStore_Brand_SPS			numeric(33,16)
	--			,InStore_Brand_RR			numeric(33,16)
	--		)

END