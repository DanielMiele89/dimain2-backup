-- =================================================================================
-- Author:		<Shaun Hide>
-- Create date: <30th March 2017>
-- Description:	<Adjustment to spenders and ATF based on time period>
-- =================================================================================
CREATE PROCEDURE [Prototype].[AMEX_SpenderAdj_v0]
AS
BEGIN
	SET NOCOUNT ON;
	------------------------------------------------------------------------------
	
	Declare @time DATETIME
	Declare @msg VARCHAR(2048)

	SELECT @msg = 'Start - Spender Adjustment'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------------------------
	--	Specify Dates
	-------------------------------------------------------------------------------------

	Declare		@startdate date
	Set			@startdate =  (select DATEADD(WEEK,-52, StartDate) from Warehouse.Prototype.AMEX_Dates)

	Declare		@enddate date
	Set			@enddate = (select EndDate from Warehouse.Prototype.AMEX_Dates)


	-------------------------------------------------------------------------------------
	--	Pre-Brand Loop Set-up
	-------------------------------------------------------------------------------------

	-- 1.5m Sample
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
						Select *
						From Staging.Customer_DuplicateSourceUID dup
						Where EndDate is null
						and	c.SourceUID = dup.SourceUID
						)
		  ) a
	order by newid()

	CREATE CLUSTERED INDEX ix_ccID on #MyRewardsBase(CINID)

	DECLARE @rowno int
	Set @rowno=1

	WHILE @rowno  <= (select max(rowno) from Warehouse.Prototype.AMEX_RefreshBrand)        
		BEGIN

			-- Single Brand Run
			--Declare		@time DATETIME
			--Declare		@msg VARCHAR(2048)
			--Declare		@startdate date
			--Set			@startdate =  (select DATEADD(WEEK,-52, StartDate) from Warehouse.Prototype.AMEX_Dates)
			--Declare		@enddate date
			--Set			@enddate = (select EndDate from Warehouse.Prototype.AMEX_Dates)
			--DECLARE		@rowno int
			--Set			@rowno=1
		
			SELECT @msg = 'RowNo ' + cast(@RowNo as varchar(3))
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			---------------------------------------------------------------------------------------------
			-- Create a single brand brand table

			IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
			Select	*
			Into	#Brand
			From	Warehouse.Prototype.AMEX_RefreshBrand
			Where	RowNo = @RowNo

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
			Set			@Lapsed = (select LapserL from  #Settings) 

			Declare		@Acquire int
			Set			@Acquire = (select AcquireL from #Settings)

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
									,'This brand does not have any details...'
					Set @rowno = @rowno + 1
					CONTINUE
				END

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

			---------------------------------------------------------------------------------------------
			-- Find 12m Historic Data

			If Object_ID('tempdb..#12monthHistoric') IS NOT NULL DROP TABLE #12monthHistoric
			Select		seg.Shopper_Segment
						,ct.CINID
						,TranDate
						,COUNT(1) as Trans
			Into		#12monthHistoric
			From		Warehouse.Relational.ConsumerTransaction ct with (nolock)
			Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			Join		#Segments seg on seg.CINID = ct.CINID
			Where		@startdate <= TranDate
					and TranDate <= @enddate
					and IsRefund = 0
			Group By	seg.Shopper_Segment
						,ct.CINID
						,TranDate

			CREATE CLUSTERED INDEX ix_CINID on #12monthHistoric(CINID)
			CREATE NONCLUSTERED INDEX ix_TranDate ON #12monthHistoric(TranDate)
		
			---------------------------------------------------------------------------------------------
			-- Generate date table
		
			If Object_ID('tempdb..#Weeks') IS NOT NULL DROP TABLE #Weeks
			;WITH IntList as
			(
			   Select 4 as Value
			   UNION ALL
			   Select	Value + 4 
			   From		IntList
			   Where	Value < 52
			)
			Select	* 
			Into	#Weeks
			From	IntList
			OPTION	(MAXRECURSION 100)

			If Object_ID('tempdb..#DateTable') IS NOT NULL DROP TABLE #DateTable
			Select		Value as WeekDiff
						,DATEADD(WEEK,-Value,a.EndDate) as StartDate
						,a.EndDate
			Into		#DateTable
			From		#Weeks
			Cross Join (Select @enddate as EndDate) a
			Where		Value in (4,8,12,24,48,52)

			If Object_ID('tempdb..#Summary') IS NOT NULL DROP TABLE #Summary
			Select	*
			Into	#Summary
			From
				(
					(
						Select 'All'					as Segment
								,b.WeekDiff				as WeekLength
								,count(distinct cinid)	as Spenders
								,sum(trans)				as Trans
								,case when count(distinct cinid) > 0 then
									sum(trans)/cast(count(distinct cinid) as real)
								 else
									NULL
								 end as ATF
						From	#12monthHistoric a
						Join	#DateTable b 
							on	b.StartDate <= a.TranDate
							and a.TranDate < b.EndDate
						Group By b.WeekDiff
					)
					union
					(
						Select	a.Shopper_Segment
								,b.WeekDiff				as WeekLength
								,count(distinct cinid)	as Spenders
								,sum(trans)				as Trans
								,case when count(distinct cinid) > 0 then
									sum(trans)/cast(count(distinct cinid) as real)
								 else
									NULL
								 end as ATF
						From	#12monthHistoric a
						Join	#DateTable b 
							on	b.StartDate <= a.TranDate
							and a.TranDate < b.EndDate
						Group By a.Shopper_Segment 
								,b.WeekDiff
					)
				) a
		
			-- select * from #Summary

			Insert Into Warehouse.Prototype.AMEX_SpenderAdj
				Select		@BrandID as BrandID
							,a.*
							,b.Spenders as BASESpenders
							,b.ATF as BASEATF
							,case when 0 < b.Spenders then
								a.Spenders / CAST(b.Spenders as Real)
							 else
								NULL
							 end as SpendersRatio
							,case when 0 < b.ATF then
								a.ATF / CAST(b.ATF as Real)
							 else
								NULL
							 end as ATFRatio
				From		#Summary a
				Left Join	(
								Select	*
								From	#Summary
								Where	WeekLength = 4
							) b 
						on a.Segment = b.Segment

			OPTION (RECOMPILE)

			Set @RowNo = @RowNo + 1
		END

	SELECT @msg = 'End - Spender Adjustment'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
	-- select * from Warehouse.Prototype.AMEX_SpenderAdj
	------------------------------------------------------------------------------
	END