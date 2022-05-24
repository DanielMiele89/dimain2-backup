-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <10/04/2017>
-- Description:	<Cumulative Gains for RBS>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_CumulGainsRBS]
AS
BEGIN
	SET NOCOUNT ON;
	-------------------------------------------------------------------------------------

	Declare @time DATETIME
	Declare @msg VARCHAR(2048)

	SELECT @msg = 'Start'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-----------------------------------
	-- Read in Dates

	Declare		@startfutureperiod date
	Set			@startfutureperiod = (select StartEightWeek from Warehouse.ExcelQuery.ROCEFT_DatesCumulativeGains)

	Declare		@endfutureperiod date
	Set			@endfutureperiod = (select EndEightWeek from Warehouse.ExcelQuery.ROCEFT_DatesCumulativeGains)

	Declare		@endhistoricperiod date
	Set			@endhistoricperiod = (select DATEADD(day,-1,@startfutureperiod))

	Declare		@rundate date
	Set			@rundate = (select RunDate from Warehouse.ExcelQuery.ROCEFT_DatesCumulativeGains)

	-------------------------------------------------------------------------------------
	--	Derive shopper / demographic features (used across all brands) for 1.5m sample
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
						Select *
						From Staging.Customer_DuplicateSourceUID dup
						Where EndDate is null
						and	c.SourceUID = dup.SourceUID
						)
		  ) a
	order by newid()

	CREATE CLUSTERED INDEX ix_ccID on #MyRewardsBase(CINID)

	-- Social-Demographics and Profiling Features (no drivetime yet)
	If Object_ID('tempdb..#DemogBase') IS NOT NULL DROP TABLE #DemogBase
	Select			a.CINID
					,c.PostalSector
					,c.Gender
					,coalesce(c.region,'Unknown') as Region
					,CASE	
						WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
						WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
						WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
						WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
						WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
						WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
						WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
						WHEN c.AgeCurrent >= 65 THEN '07. 65+' 
					END AS Age_Group
					,ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO_CODE_GRP
					,c.MarketableByEmail
					,CASE
						WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
						WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
						WHEN c.AgeCurrent BETWEEN 25 AND 34 THEN '02. 25 to 34'
						WHEN c.AgeCurrent BETWEEN 35 AND 44 THEN '03. 35 to 44'
						WHEN c.AgeCurrent BETWEEN 45 AND 54 THEN '04. 45 to 54'
						WHEN c.AgeCurrent BETWEEN 55 AND 64 THEN '05. 55 to 64'
						WHEN c.AgeCurrent BETWEEN 65 AND 80 THEN '06. 65 to 80'
						WHEN c.AgeCurrent >= 81 THEN '07. 81+' 
					 END AS Age_Group_2
					,isnull(camg.Social_Class,'U') as Social_Class
	Into			#DemogBase
	From			#MyRewardsBase a
	Inner Join		Relational.CINList cl on a.CINID = cl.CINID
	Inner Join		Relational.Customer c on cl.CIN = c.SourceUID
	Left Join		Relational.CAMEO cam on c.PostCode = cam.PostCode
	Left Join		Relational.CAMEO_CODE_GROUP camg on camg.CAMEO_CODE_GROUP = cam.CAMEO_CODE_GROUP

	CREATE CLUSTERED INDEX ix_CINID on #DemogBase(CINID)

	If Object_ID('tempdb..#ShopperBase') IS NOT NULL DROP TABLE #ShopperBase
	Select		a.*
				,lk2.ComboID
	Into		#ShopperBase
	From		#DemogBase a
	Left Join	InsightArchive.HM_Combo_SalesSTO_Tool lk2 
			on	a.gender=lk2.gender 
			and a.CAMEO_CODE_GRP=lk2.CAMEO_grp 
			and a.Age_Group=lk2.Age_Group

	CREATE CLUSTERED INDEX ix_CINID on #ShopperBase(CINID)

	SELECT @msg = 'Shopper base and demographics applied (excl. Drivetime)'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	DECLARE @BrandID int, @rowno int
	Set @rowno=1

	WHILE @rowno  <= (select max(rowno) from Warehouse.ExcelQuery.ROCEFT_RefreshBrand)        
		BEGIN
			-- BREAKING THE LOOP FOR TESTING
			--DECLARE @time DATETIME
			--DECLARE @msg VARCHAR(2048)
			--DECLARE @BrandID int
			--DECLARE @rowno int
			--Set @rowno=1
			--Declare		@startfutureperiod date
			--Set			@startfutureperiod = (select StartEightWeek from Warehouse.ExcelQuery.ROCEFT_DatesCumulativeGains)

			--Declare		@endfutureperiod date
			--Set			@endfutureperiod = (select EndEightWeek from Warehouse.ExcelQuery.ROCEFT_DatesCumulativeGains)

			--Declare		@endhistoricperiod date
			--Set			@endhistoricperiod = (select DATEADD(day,-1,@startfutureperiod))

			--Declare		@rundate date
			--Set			@rundate = (select RunDate from Warehouse.ExcelQuery.ROCEFT_DatesCumulativeGains)
			-- END OF LOOP BREAK
			

			-- START OF LOOP

			-- Create a single brand brand table
			IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
			Select	*
			Into	#Brand
			From	Warehouse.ExcelQuery.ROCEFT_RefreshBrand with (nolock)
			Where	RowNo = @RowNo

			-- select * from #Brand
			Set @BrandID = (select brandid from #Brand where rowno=@rowno)
			Print 'Row Number: ' + cast(@rowno as varchar(10))
			Print 'BrandID: ' + cast(@BrandID as varchar(10))

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

			Declare		@starthistoricperiod date
			Set			@starthistoricperiod = (dateadd(month,-@Acquire,@startfutureperiod))

			SELECT @msg = 'Acquire/Lapsed Length determined'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			---------------------------------------------------------------------------------------------
			-- Identify the relevant consumer combination IDs
		
			If Object_ID('tempdb..#cc') IS NOT NULL DROP TABLE #cc
			Select	cc.brandid
					,ConsumerCombinationID
			Into	#cc
			From	Relational.ConsumerCombination cc
			Join	#Brand br on br.BrandID=cc.BrandID
			Where	cc.IsUKSpend = 1

			CREATE NONCLUSTERED INDEX ix_brandID on #cc(BrandID)
			CREATE CLUSTERED INDEX ix_ccID on #cc(ConsumerCombinationID)

			SELECT @msg = 'Relevant consumer combinations determined'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

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
					and trandate between @starthistoricperiod and @endhistoricperiod
			Group By	ct.CINID

			CREATE CLUSTERED INDEX ix_CINID on #HistoricSpend(CINID)

			SELECT @msg = 'Historic spend data for brand found'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			---------------------------------------------------------------------------------------------
			-- Future spend

			If object_id('tempdb..#FutureSpend') is not null drop table #FutureSpend
			Select		ct.CINID
						,sum(Amount) as future_Spend
						,count(1) as future_Frequency
						,1 as future_spender
			Into		#FutureSpend
			From		Relational.ConsumerTransaction ct with (nolock)
			Join		#MyRewardsBase c on c.cinid=ct.cinid
			Join		#cc b on b.ConsumerCombinationID=ct.ConsumerCombinationID
			Where		ISRefund = 0 
					and trandate between @startfutureperiod and @endfutureperiod
			Group By	ct.CINID

			CREATE CLUSTERED INDEX ix_CINID on #FutureSpend(CINID)

			SELECT @msg = 'Future spend data for brand found'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			---------------------------------------------------------------------------------------------
			-- Segment assignment and ranking variables joined to CINID list

			If Object_ID('tempdb..#Combination') IS NOT NULL DROP TABLE #Combination
			Select		a.*
						,isnull(hm.Index_RR,100)		as Heatmap_Score
						,isnull(hist.Spend,0)			as Past_Spend
						,isnull(hist.Frequency,0)		as Past_Frequency
						,case 
							when isnull(DATEDIFF(MONTH,LastDate,(@endhistoricperiod)),9999) <= @Lapsed then 'Shopper'				
							when isnull(DATEDIFF(MONTH,LastDate,(@endhistoricperiod)),9999) <= @Acquire then 'Lapsed' else 'Acquire' 
						 end as Shopper_Segment
						,isnull(fut.future_Spend,0)		as Future_Spend
						,isnull(fut.future_Frequency,0) as Future_Frequency
						,isnull(fut.future_spender,0)	as Future_Spender
			Into		#Combination
			From		#ShopperBase a
			Left Join	#HistoricSpend hist on	a.CINID = hist.CINID
			Left Join	#FutureSpend fut on a.CINID = fut.CINID				
			Left Join	(	
							Select *
							From Warehouse.ExcelQuery.ROCEFT_HeatmapBrandCombo_Index 
							Where BrandID = @BrandID
						) hm
					on	a.ComboID = hm.ComboID
		
			CREATE CLUSTERED INDEX ix_CINID on #Combination(CINID)

			---------------------------------------------------------------------------------------------
			-- Ranking and Deciling
		 
			If Object_ID('tempdb..#Ranking_1') IS NOT NULL DROP TABLE #Ranking_1
			Select		a.*
						,case when Shopper_Segment = 'Acquire' then
							ROW_NUMBER() over(partition by Shopper_Segment order by Heatmap_Score desc)
						 else
							ROW_NUMBER() over(partition by Shopper_Segment order by Past_Spend desc)
						 end as Ranking_Within_Segment
			Into		#Ranking_1
			From		#Combination a

			If Object_ID('tempdb..#Ranking_2') IS NOT NULL DROP TABLE #Ranking_2
			select		a.*
						,ntile(10) over(partition by Shopper_Segment order by Ranking_Within_Segment asc) as Deciles
			into		#Ranking_2
			from		#Ranking_1 a

			CREATE CLUSTERED INDEX ix_CINID on #Ranking_2(CINID)

			SELECT @msg = 'Ranking and Deciling complete'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			---------------------------------------------------------------------------------------------
			-- Drivetime if partner

			If Object_ID('tempdb..#Partners') IS NOT NULL DROP TABLE #Partners
			Select		br.BrandID
						,br.BrandName
						,p.PartnerID
						,p.PartnerName
						,case when p.PartnerID IS NULL then	0 else 1 end as HasPartner
			Into		#Partners
			From		#Brand br
			Left Join	Relational.Partner p on br.BrandID = p.BrandID		

			Declare @PartnerCount Int
			Set @PartnerCount = (Select sum(HasPartner) From #Partners)

			If Object_ID('tempdb..#DriveTime') IS NOT NULL DROP TABLE #DriveTime
			CREATE TABLE #DriveTime
				(
					PostalSector varchar(50)
					,Nearest_Store int
				)

			IF @PartnerCount <> 0
				Begin
					If Object_ID('tempdb..#PostcodesByPartner') IS NOT NULL DROP TABLE #PostcodesByPartner
					Select		O.*
								,b.PartnerName
								,b.BrandID
								,b.BrandName
					Into		#PostcodesByPartner
					From		Relational.Outlet O
					Join		SLC_REPORT.DBO.RetailOutlet AS RO ON O.OutletID = RO.ID
					Join		#Partners b on ro.PartnerID = b.PartnerID
					Where		ro.SuppressFromSearch = 0 
								and Region is not null
				
					CREATE INDEX ix_PostalSector on #PostcodesByPartner(PostalSector)
				
					Insert Into #DriveTime
						Select		ps.PostalSector
									,MIN(DriveTimeMins) as Nearest_Store
						From		#Ranking_2 ps
						Join		Relational.DriveTimeMatrix dtm
									ON ps.PostalSector = dtm.FromSector
						Join		#PostcodesByPartner pc
									ON dtm.ToSector = pc.PostalSector
						Group By	ps.PostalSector
				End
		
			If Object_ID('tempdb..#Profiling') IS NOT NULL DROP TABLE #Profiling
			Select		a.*
						,case
							when dt.Nearest_Store <= 25 then '01. Within 25 mins'
							when dt.Nearest_Store > 25 then '02.More than 25 mins'
							else '03. Unknown'
						 end as DriveTimeBand
			Into		#Profiling
			From		#Ranking_2 a
			Left Join	#DriveTime dt 
					on	a.PostalSector = dt.PostalSector

			SELECT @msg = 'Drivetime assignment complete'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			---------------------------------------------------------------------------------------------
			-- RBS Profiling
		 
			If Object_ID('tempdb..#Topline') IS NOT NULL DROP TABLE #Topline
			Select	Shopper_Segment
					,count(distinct CINID)	as TotalShoppers
					,count(distinct (case when Past_Spend > 0 then CINID end)) as TotalHisSpenders
					,sum(Past_Spend)		as TotalHisSpend
					,sum(Past_Frequency)	as TotalHisTrans
					,sum(Future_Spender)    as TotalFutSpenders
					,sum(Future_Spend)		as TotalFutSpend
					,sum(Future_Frequency)	as TotalFutTrans
			Into	#Topline
			From	#Profiling
			Group by Shopper_Segment

			Insert Into	Warehouse.ExcelQuery.ROCEFT_RBSCumulativeGains
				Select	'RBS' as Publisher
						,a.BrandID
						,a.Shopper_Segment
						,a.Deciles
						,a.Gender
						,case 
							when a.Age_Group_2 = '01. 18 to 24' then
								1
							 when a.Age_Group_2 = '02. 25 to 34' then
								2
							 when a.Age_Group_2 = '03. 35 to 44' then
								3
							 when a.Age_Group_2 = '04. 45 to 54' then
								4
							 when a.Age_Group_2 = '05. 55 to 64' then
								5
							 when a.Age_Group_2 = '06. 65 to 80' then
								6
							 when a.Age_Group_2 = '07. 81+' then
								7
							 else 
								8
						 end as Age_Group
						,case
							when a.Social_Class = 'AB' then
								1
							when a.Social_Class = 'C1' then
								2
							when a.Social_Class = 'C2' then
								3
							when a.Social_Class = 'DE' then
								4
							else
								5
						 end as Social_Class
						,a.MarketableByEmail
						,a.DriveTimeBand
						,cast(round(coalesce((1.0*Cardholder_Count)/nullif(TotalShoppers,0),0),11) as decimal(12,11))	as ProportionOfCardholders
						,cast(round(coalesce((1.0*Spender_Count)/nullif(TotalFutSpenders,0),0),11) as decimal(12,11))	as ProportionOfSpenders
						,cast(round(coalesce((1.0*Spend_Count)/nullif(TotalFutSpend,0),0),11) as decimal(12,11))		as ProportionOfSpend
						,cast(round(coalesce((1.0*Frequency_Count)/nullif(TotalFutTrans,0),0),11) as decimal(12,11)) 	as ProportionOfTrans
				From	(
							Select	@BrandID as BrandID
									,Shopper_Segment
									,Deciles
									,Gender
									,Age_Group_2
									,Social_Class
									,MarketableByEmail
									,DriveTimeBand
									,count(distinct CINID)	as Cardholder_Count	
									,sum(Future_Spender)	as Spender_Count
									,sum(Future_Spend)		as Spend_Count
									,sum(Future_Frequency)	as Frequency_Count
							From	#Profiling
							Group By Shopper_Segment
									,Deciles
									,Gender
									,Age_Group_2
									,Social_Class
									,MarketableByEmail
									,DriveTimeBand
						) a
				Join	#Topline b
					on  a.Shopper_Segment = b.Shopper_Segment
				Order By a.Shopper_Segment
						,a.Deciles
						,a.Gender
						,case 
							when a.Age_Group_2 = '01. 18 to 24' then
								1
							 when a.Age_Group_2 = '02. 25 to 34' then
								2
							 when a.Age_Group_2 = '03. 35 to 44' then
								3
							 when a.Age_Group_2 = '04. 45 to 54' then
								4
							 when a.Age_Group_2 = '05. 55 to 64' then
								5
							 when a.Age_Group_2 = '06. 65 to 80' then
								6
							 when a.Age_Group_2 = '07. 81+' then
								7
							 else 
								8
						 end
						,case
							when a.Social_Class = 'AB' then
								1
							when a.Social_Class = 'C1' then
								2
							when a.Social_Class = 'C2' then
								3
							when a.Social_Class = 'DE' then
								4
							else
								5
						 end
						,a.MarketableByEmail
						,a.DriveTimeBand

			-- select * from Warehouse.ExcelQuery.ROCEFT_RBSCumulativeGains

			OPTION (RECOMPILE)

			-- END OF LOOP

			SELECT @msg = 'Loop just finished ' + cast(@rowno as varchar(10)) + '. Insertion has been successful'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			Set @rowno = @rowno +1

		END

END
