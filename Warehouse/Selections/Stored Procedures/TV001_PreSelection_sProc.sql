-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure  [Selections].[TV001_PreSelection_sProc]
AS
BEGIN
	SET ANSI_WARNINGS OFF;

Declare @Step INT = 1

If @Step = 1
	Begin

			/************************************************************************/
			/****** Warning: query designed to be run in steps, not as a whole ******/
			/************************************************************************/

			-- Get customers, add columns as needed
			if object_id('tempdb..#AllCustomers') is not null drop table #AllCustomers
			CREATE TABLE #AllCustomers (fanid INT NOT NULL
				   ,cinid INT NOT NULL
				   ,TLD_LatestTx varchar(30) 
				   ,TLD_Freq12Mon int
				   ,TLD_SoW float
				   ,HotelTxs int
				   ,TrainTxs int
				   ,TrainAndHotelTxs int
				   ,Business varchar(30) 
				   ,Parent int
				   ,OTA int
				   ,Propensity int
				   ,PropensityCat varchar(30) 
				   ,HMscore int
				   ,LookAlike varchar(30)
				   ,MainSegment varchar(30) 
				   )



			-- Fill table with chunk sizing
			DECLARE @MinID INT, @MaxID INT, @Increment INT = 500000, @MaxIDValue INT
			SELECT @MaxIDValue = MAX(FanID) FROM Warehouse.Relational.Customer
			SET @MinID = 1
			SET @MaxID = @Increment

			WHILE @MinID < @MaxIDValue
			BEGIN

			 INSERT INTO #AllCustomers
			 SELECT      
				c.FanID
				,cl.cinid
				,cast(NULL as varchar(30))
				,cast(NULL as int)
				,cast(NULL as float)
				,cast(NULL as int)
				,cast(NULL as int)
				,cast(NULL as int)
				,cast(NULL as varchar(30))
				,cast(NULL as int)
				,cast(NULL as int)
				,cast(NULL as int)
				,cast(NULL as varchar(30))
				,cast(NULL as int)
				,cast(NULL as varchar(30))
				,cast(NULL as varchar(30))

			 FROM Warehouse.Relational.Customer c  WITH (NOLOCK)
			 LEFT OUTER JOIN Warehouse.Relational.CAMEO cam  WITH (NOLOCK)
			  ON c.PostCode = cam.Postcode
			 LEFT OUTER JOIN Warehouse.Relational.CAMEO_CODE_GROUP camg  WITH (NOLOCK)
			  ON cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP
			 INNER JOIN warehouse.relational.CINList as cl 
			  ON c.SourceUID=cl.CIN
			 inner join warehouse.mi.customeractivationperiod cap on cap.fanid = c.fanid
			 WHERE 
			 c.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
			 and c.fanID between @MinID and @MaxID
			 and currentlyactive = 1


			 SET @MinID = @MinID + @Increment
			 SET @MaxID = @MaxID + @Increment

			END




			---- Add fields
			---- Latest Travelodge transaction (up to 24 months)
			--alter table #AllCustomers
			--add TLD_LatestTx varchar(30) 


			--alter table #AllCustomers
			--add TLD_Freq12Mon int


			---- Share of wallet
			--alter table #AllCustomers
			--add TLD_SoW float


			---- Attach all else
			--alter table #AllCustomers
			--add HotelTxs int 

			--alter table #AllCustomers
			--add TrainTxs int 


			--alter table #AllCustomers
			--add TrainAndHotelTxs int 


			---- Attach Business
			--alter table #AllCustomers
			--add Business varchar(20)


			---- Attach 'Families' flag
			--alter table #AllCustomers
			--add Parent int 


			---- Attach 'OTAs' flag
			--alter table #AllCustomers
			--add OTA int 


			---- Attach propensity for acquire
			--alter table #AllCustomers
			--add Propensity int


			--alter table #AllCustomers
			--add PropensityCat varchar(20)


			---- This is heatmap
			--alter table #AllCustomers
			--add HMscore int 


			--alter table #AllCustomers
			--add LookAlike varchar(20) 


			--alter table #AllCustomers
			--add MainSegment varchar(20) 



			-- Declarations
			declare @Today date = getdate()
			declare @6MonthsAgo date = dateadd(month, -6, @Today)
			declare @12MonthsAgo date = dateadd(month, -12, @Today)
			declare @18MonthsAgo date = dateadd(month, -18, @Today)
			declare @24MonthsAgo date = dateadd(month, -24, @Today)



			-- Fill in fields
			IF OBJECT_ID('tempdb..#CCs') IS NOT NULL DROP TABLE #CCs
			select consumercombinationID
			into #CCs
			from warehouse.relational.consumercombination
			where
			BrandID = 468

			create clustered index IONXC on #CCs(consumercombinationID)



			if object_id('tempdb..#Sales') is not null drop table #Sales
			select ct.CINID
			  ,sum(amount) as sales 
			  ,count(1) as Txs 
			  ,sum(case when ct.trandate >= @12MonthsAgo then 1 else 0 end) as Txs12Mon
			  ,max(ct.trandate) as LatestTx
			  ,sum(case when ct.trandate >= @12MonthsAgo then ct.Amount else 0 end) as sales_12Mon

			into #Sales
			from #CCs b
			INNER JOIN Warehouse.Relational.ConsumerTransaction ct on b.ConsumerCombinationID=ct.ConsumerCombinationID
			INNER JOIN #AllCustomers c on c.cinid = ct.cinid
			where
			TranDate between @24MonthsAgo and @Today
			group by 
			ct.cinid

			-- Date ran: 28/09/2017



			-- Categorise these customers
			update a
			set 
			a.TLD_LatestTx = case 
					when b.LatestTx >= @6MonthsAgo then  'Last6Months'
				 when b.LatestTx >= @12MonthsAgo then  'Last12Months'
					when b.LatestTx >= @18MonthsAgo then  'Last18Months'
				 when b.LatestTx >= @24MonthsAgo then  'Last24Months'
				 else 'Acquisition'end,
			a.TLD_Freq12Mon = case when b.Txs12Mon is null then 0 else b.Txs12Mon end

			from #AllCustomers a
			left join #Sales b on b.CINID = a.CINID

			-- Date ran: 28/09/2017



			-- Get Hotel transactions
			if object_id('tempdb..#CC_Hotel') is not null drop table #CC_Hotel
			select cc.ConsumerCombinationID
			into #CC_Hotel
			from Relational.brand b
			inner join relational.ConsumerCombination cc on cc.BrandID = b.BrandID
			where
			sectorid = 21

			create clustered index INX on #CC_Hotel(ConsumerCombinationID)


			-- Run the above in an other way in order to get total Hotel spend

			if object_id('tempdb..#Sales_Hotel_total') is not null drop table #Sales_Hotel_total
			select ct.CINID, sum(ct.amount) as sales
			into #Sales_Hotel_total
			from #CC_Hotel b
			INNER JOIN Warehouse.Relational.ConsumerTransaction ct on b.ConsumerCombinationID=ct.ConsumerCombinationID
			INNER JOIN #AllCustomers c on c.cinid = ct.cinid
			where
			TranDate between @12MonthsAgo and @Today
			group by 
			ct.CINID



			-- Calculate share of wallet
			if object_id('tempdb..#TLD_SoW') is not null drop table #TLD_SoW
			select s.cinid,
			case when ht.sales = 0 then 0 else 1.00*s.sales_12Mon / ht.sales end as SoW
			into #TLD_SoW
			from #Sales s
			inner join #Sales_Hotel_total ht on ht.cinid = s.CINID

	Set @Step = @Step + 1
	End

If @Step = 2
	Begin

			-- Construct metrics for locating business users
			if object_id('tempdb..#CC_TrainMarket') is not null drop table #CC_TrainMarket
			select ConsumerCombinationID
			into #CC_TrainMarket
			from Relational.ConsumerCombination cc
			inner join 
			relational.Brand b on cc.BrandID = b.BrandID
			where
			brandname like '%London & South East Rail%' or
			brandname like '%Trainline%' or
			brandname like '%Virgin Trains%' or
			brandname like '%Great Western Railway%' or
			brandname like '%Southern Railways%' or
			brandname like '%Thameslink Southern and Great Northern%' or
			brandname like '%Greater Anglia Trains%' or
			brandname like '%Abellio ScotRail%' or
			brandname like '%South West Trains%' or
			brandname like '%West Coast Trains%' or
			brandname like '%East Midlands Trains%' or
			brandname like '%London Midland Trains%' or
			brandname like '%C2C Rail%' or
			brandname like '%Arriva Trains%' or
			brandname like '%Northern Rail%' or
			brandname like '%The Chiltern Railway%' or
			brandname like '%First Group Trains%' or
			brandname like '%Cross Country Trains%' or
			brandname like '%First ScotRail%' or
			brandname like '%Heathrow Express%' or
			brandname like '%Hailo%' or
			brandname like '%Rail Easy%' or
			brandname like '%Red Spotted Hanky Trains%' or
			brandname like '%West Coast Trains Parking%' or
			brandname like '%Transpennine Express%' or
			brandname like '%Gatwick Express%' or
			brandname like '%First Hull Trains%' or
			brandname like '%London Eastern Rail%' or
			brandname like '%Grand Central Rail%' or
			brandname like '%Severn Valley Rail%' or
			brandname like '%East West Rail%' or
			brandname like '%West Somerset Rail%' or
			brandname like '%Take The Train%' or
			brandname like '%East Coast Mainline Trains%' or
			brandname like '%Merseyrail%' or
			brandname like '%Ffestiniog & Welsh Highland Railways%' or
			brandname like '%My Train Ticket%' 

			Create clustered index cix_Brands_BrandID on #CC_TrainMarket(ConsumerCombinationID)



			if object_id('tempdb..#Sales_TrainMarket') is not null drop table #Sales_TrainMarket
			select ct.CINID, ct.TranDate
			into #Sales_TrainMarket
			from #CC_TrainMarket b
			INNER JOIN Warehouse.Relational.ConsumerTransaction ct on b.ConsumerCombinationID=ct.ConsumerCombinationID
			INNER JOIN #AllCustomers c on c.cinid = ct.cinid
			where
			TranDate between @12MonthsAgo and @Today

			-- Date ran: 28/09/2017




			if object_id('tempdb..#Sales_Hotel') is not null drop table #Sales_Hotel
			select ct.CINID, ct.TranDate
			into #Sales_Hotel
			from #CC_Hotel b
			INNER JOIN Warehouse.Relational.ConsumerTransaction ct on b.ConsumerCombinationID=ct.ConsumerCombinationID
			INNER JOIN #AllCustomers c on c.cinid = ct.cinid
			where
			TranDate between @12MonthsAgo and @Today

			-- Date ran: 28/09/2017




			-- Get the combination
			if object_id('tempdb..#Sales_Tmarket_H_Combination') is not null drop table #Sales_Tmarket_H_Combination
			select ag.cinid, count(1) as Txs
			into #Sales_Tmarket_H_Combination
			from (
			 select t.CINID, t.TranDate
			 from #Sales_TrainMarket t
			 inner join #Sales_Hotel sh on sh.CINID = t.CINID and sh.TranDate between dateadd(WEEK,-2, t.TranDate) and dateadd(WEEK,2, t.TranDate)
			 group by 
			 t.CINID, t.TranDate
			) ag 
			group by 
			ag.cinid




			update t 
			set TrainAndHotelTxs = case when tr.Txs is null then 0 else tr.Txs end
			from #AllCustomers t
			left join  #Sales_Tmarket_H_Combination tr on tr.CINID = t.cinid



			update t set
			Business = case when TrainAndHotelTxs >= 2 then 'Yes' else 'No' end 
			from #AllCustomers t



			update t 
			set HotelTxs = case when h.Txs is null then 0 else h.Txs end
			from #AllCustomers t
			left join (
			select cinid, count(1) as Txs
			from #Sales_Hotel
			group by 
			cinid
			) h on h.CINID = t.cinid



			update t 
			set TrainTxs = case when tr.Txs is null then 0 else tr.Txs end
			from #AllCustomers t
			left join (
			select cinid, count(1) as Txs
			from #Sales_TrainMarket
			group by 
			cinid
			) tr on tr.CINID = t.cinid




			update t 
			set TLD_SoW = case when tr.SoW is null then 0 else tr.SoW end
			from #AllCustomers t
			left join  #TLD_SoW tr on tr.CINID = t.cinid

			-- Correct for SoW = 0 but freq > 0. These are refunds
			update t set 
			TLD_LatestTx = 'Acquisition',
			TLD_Freq12Mon = NULL

			from #AllCustomers t
			where
			TLD_Freq12Mon > 0 
			and TLD_SoW = 0 
			and TLD_LatestTx in ('Last6Months', 'Last12Months')



			update t 
			set Parent = case when p.CINID is null then 0 else 1 end
			from #AllCustomers t
			left join  
			( select cinid
			 from Relational.CustomerAttribute
			 where
			 Parent = 1 )
			p on p.CINID = t.cinid



			if object_id('tempdb..#OTAs') is not null drop table #OTAs
			select Brandid
			into #OTAs
			from relational.brand b
			where
			(
			brandname like '%Agoda%'
			or brandname like '%Alpha%Rooms%'
			or brandname like '%Amazon Destinations%'
			or brandname like '%Asia%Rooms%'
			or brandname like '%Asia%Travel%'
			or brandname like '%Asia%Web%Direct%'
			or brandname like '%Bedbooker%'
			or brandname like '%Best%Hotel%Online%'
			or brandname like '%Booking.com%'
			or brandname like '%Bookit%'
			or brandname like '%Budget%Places%'
			or brandname like '%Cheapo%Air%'
			or brandname like '%Cheapoair%'
			or brandname like '%Cheaptickets%'
			or brandname like '%Cleartrip%'
			or brandname like '%Ctrip%'
			or brandname like '%Destinia%'
			or brandname like '%Easy%to%Book%'
			or brandname like '%ebookers%'
			or brandname like '%Ebooking%'
			or brandname like '%edreams%'
			or brandname like '%Expedia%'
			or brandname like '%Goibibo%'
			or brandname like '%Holiday%City%'
			or brandname like '%Horse%21%'
			or brandname like '%Hostelbookers%'
			or brandname like '%Hostelworld%'
			or brandname like '%Hotel%Direct%'
			or brandname like '%Hotel%Reservations%'
			or brandname like '%Hotel%Travel%'
			or brandname like '%Hotel.de%'
			or brandname like '%Hotelclub%'
			or brandname like '%Hotelius%'
			or brandname like '%Hotels.com%'
			or brandname like '%Hotels4U%'
			or brandname like '%HRS%'
			or brandname like '%Internet Hotels%'
			or brandname like '%Lastminute.com%'
			or brandname like '%Late%Deals%'
			or brandname like '%Laterooms%'
			or brandname like '%Logitravel%'
			or brandname like '%Low%Cost%Holidays%'
			or brandname like '%Make%my%trip%'
			or brandname like '%Make%My%Trip%'
			or brandname like '%More%Hotels%for%Less%'
			or brandname like '%Mr.%Jet%'
			or brandname like '%Netflights%'
			or brandname like '%One%Travel%'
			or brandname like '%Onhotels%'
			or brandname like '%Opodo%'
			or brandname like '%Orbitz%'
			or brandname like '%Orbitz%'
			or brandname like '%Otel%'
			or brandname like '%Quikbook%'
			or brandname like '%Rates2go%'
			or brandname like '%Skoosh%'
			or brandname like '%STA%Travel%'
			or brandname like '%Think Hotels%'
			or brandname like '%Thinkhotels%'
			or brandname like '%Travelbag%'
			or brandname like '%Travelgenio%'
			or brandname like '%Travelguru%'
			or brandname like '%Travelocity%'
			or brandname like '%Travelrepublic%'
			or brandname like '%Vayama%'
			or brandname like '%Venere%'
			or brandname like '%Wego%'
			or brandname like '%Wotif%')
			and sectorid < 21




			if object_id('tempdb..#CC_OTA') is not null drop table #CC_OTA
			select cc.ConsumerCombinationID
			into #CC_OTA
			from #OTAs b
			inner join relational.ConsumerCombination cc on cc.BrandID = b.BrandID

			create clustered index INX on #CC_OTA(ConsumerCombinationID)



			if object_id('tempdb..#Sales_OTAs') is not null drop table #Sales_OTAs
			select ct.CINID, ct.TranDate
			into #Sales_OTAs
			from #CC_OTA b
			INNER JOIN Warehouse.Relational.ConsumerTransaction ct on b.ConsumerCombinationID=ct.ConsumerCombinationID
			INNER JOIN #AllCustomers c on c.cinid = ct.cinid
			where
			TranDate between @12MonthsAgo and @Today

			-- Date ran: 28/09/2017



			update t 
			set OTA = case when tr.Txs is null then 0 else tr.Txs end
			from #AllCustomers t
			left join (
			select cinid, count(1) as Txs
			from #Sales_OTAs
			group by 
			cinid
			) tr on tr.CINID = t.cinid



			-- Add gender and age
			select t.fanid, t.cinid, c.Gender
			,CASE  
			 WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
			 WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
			 WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
			 WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
			 WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
			 WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
			 WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
			 WHEN c.AgeCurrent >= 65 THEN '07. 65+' 
			END as Age_Group
			,ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO_CODE_GRP

			into #Base
			from #AllCustomers t
			inner join relational.customer c on c.fanid = t.fanid
			LEFT OUTER JOIN Warehouse.Relational.CAMEO cam  WITH (NOLOCK)
			  ON c.PostCode = cam.Postcode
			LEFT OUTER JOIN Warehouse.Relational.CAMEO_CODE_GROUP camg  WITH (NOLOCK)
			  ON cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP




			IF OBJECT_ID('tempdb..#Activated_HM') IS NOT NULL DROP TABLE #Activated_HM
			select a.*
			,lk2.comboID as ComboID_2 -- Gender / Age group and Cameo grp
			into #Activated_HM
			from #Base a  -- full base
			left join Warehouse.InsightArchive.HM_Combo_SalesSTO_Tool lk2 on a.gender=lk2.gender and a.CAMEO_CODE_GRP=lk2.CAMEO_grp and a.Age_Group=lk2.Age_Group




			IF OBJECT_ID('tempdb..#Activated_HM2') IS NOT NULL DROP TABLE #Activated_HM2
			select b.*
			,hm.Index_RR
			,lk.UnknownGroup
			,case when lk.UnknownGroup = 1 then 100 else Index_RR end as Response_Index
			into #Activated_HM2
			from #Activated_HM b
			left join Warehouse.InsightArchive.SalesSTO_HeatmapBrandCombo_Index hm on b.ComboID_2=hm.ComboID_2 and hm.brandid=468
			left join Warehouse.InsightArchive.HM_Combo_SalesSTO_Tool lk on lk.comboID=hm.ComboID_2


			create clustered index INX on #Activated_HM2(fanid)




			update t
			set HMscore = a.Response_Index
			from #AllCustomers t
			inner join #Activated_HM2 a on a.fanid = t.fanid




			update t
			set LookAlike = case when t.HMscore >= 110 then 'Yes' else 'No' end 
			from #AllCustomers t




			update t
			set MainSegment = case 
				 when Business = 'Yes' then 'Business'  
				 when Parent = 1 then 'Family'
				  else 'Leisure' end 
			from #AllCustomers t




			IF OBJECT_ID('tempdb..#Prop') IS NOT NULL DROP TABLE #Prop
			select cinid,HotelTxs,OTA,HMscore, 
			ROW_NUMBER() over (partition by MainSegment order by HotelTxs desc, OTA desc, HMscore desc) as Prop, 
			Ntile(3) over (partition by MainSegment order by HotelTxs desc, OTA desc, HMscore desc) as Category
			into #Prop
			from #AllCustomers
			where
			TLD_LatestTx = 'Acquisition'




			update t set 
			Propensity = case when p.Prop is null then 0 else Prop end,
			PropensityCat = case when p.Category is null then 0 else Category end

			from #AllCustomers t
			left join #Prop p on p.cinid = t.cinid




			IF OBJECT_ID('tempdb..#Selection') IS NOT NULL DROP TABLE #Selection
			-- This is the filtered table from which natural sales ppl will be selected. 
			-- Note: From these people, we do not remove those who are Business and spent in the last 6 months in order to have them for natural sales calculation.
			select TLD_LatestTx, MainSegment, PropensityCat, cinid, fanid

			into #Selection
			from #AllCustomers
			where
			not (MainSegment = 'Business' and TLD_LatestTx = 'Last6Months')  and
			not (MainSegment = 'Business' and TLD_Freq12Mon > 5) and
			not (MainSegment = 'Leisure' and TLD_Freq12Mon > 2)




			IF OBJECT_ID('tempdb..#SelectionCategories') IS NOT NULL DROP TABLE #SelectionCategories
			SELECT fanid, 
			case 
			when MainSegment = 'Business' and TLD_LatestTx = 'Acquisition' and PropensityCat = 3 then 'TV001'
			when MainSegment = 'Business' and TLD_LatestTx = 'Acquisition' and PropensityCat = 2 then 'TV002'
			when MainSegment = 'Business' and TLD_LatestTx = 'Acquisition' and PropensityCat = 1 then 'TV003'

			when MainSegment = 'Business' and TLD_LatestTx = 'Last12Months' then 'TV004'
			when MainSegment = 'Business' and TLD_LatestTx = 'Last18Months' then 'TV005'
			when MainSegment = 'Business' and TLD_LatestTx = 'Last24Months' then 'TV006'

			when MainSegment = 'Family' and TLD_LatestTx = 'Acquisition' and PropensityCat = 3 then 'TV007'
			when MainSegment = 'Family' and TLD_LatestTx = 'Acquisition' and PropensityCat = 2 then 'TV008'
			when MainSegment = 'Family' and TLD_LatestTx = 'Acquisition' and PropensityCat = 1 then 'TV009'

			when MainSegment = 'Family' and TLD_LatestTx = 'Last6Months' then 'TV010'
			when MainSegment = 'Family' and TLD_LatestTx = 'Last12Months' then 'TV011'
			when MainSegment = 'Family' and TLD_LatestTx = 'Last18Months' then 'TV012'
			when MainSegment = 'Family' and TLD_LatestTx = 'Last24Months' then 'TV013'

			when MainSegment = 'Leisure' and TLD_LatestTx = 'Acquisition' and PropensityCat = 3 then 'TV014'
			when MainSegment = 'Leisure' and TLD_LatestTx = 'Acquisition' and PropensityCat = 2 then 'TV015'
			when MainSegment = 'Leisure' and TLD_LatestTx = 'Acquisition' and PropensityCat = 1 then 'TV016'

			when MainSegment = 'Leisure' and TLD_LatestTx = 'Last6Months' then 'TV017'
			when MainSegment = 'Leisure' and TLD_LatestTx = 'Last12Months' then 'TV018'
			when MainSegment = 'Leisure' and TLD_LatestTx = 'Last18Months' then 'TV019'
			when MainSegment = 'Leisure' and TLD_LatestTx = 'Last24Months' then 'TV020'
			end as ClientServicesRef

			into #SelectionCategories
			from #Selection




			IF OBJECT_ID('tempdb..#ThrottleCountsPreID') IS NOT NULL DROP TABLE #ThrottleCountsPreID
			select ClientServicesRef, cast(count(1) * 
			case 
			when ClientServicesRef in ('TV001', 'TV002', 'TV003', 'TV004','TV005','TV006','TV011','TV013','TV018','TV019', 'TV020') then 0.7
			when ClientServicesRef in ('TV007', 'TV008', 'TV009') then 0.75
			when ClientServicesRef in ('TV014', 'TV015', 'TV016') then 0.92
			when ClientServicesRef in ('TV010', 'TV012', 'TV017') then 0.8 end as int) as ThrottleProportion

			into #ThrottleCountsPreID
			from #SelectionCategories
			group by
			ClientServicesRef
			order by 1




			IF OBJECT_ID('tempdb..#ThrottleCounts') IS NOT NULL DROP TABLE #ThrottleCounts
			select t.*, row_number() over (order by clientservicesref desc) as ID
			into #ThrottleCounts
			from #ThrottleCountsPreID t




			IF OBJECT_ID('tempdb..#FinalSelection') IS NOT NULL DROP TABLE #FinalSelection
			create table #FinalSelection (fanid int,
					 clientservicesref varchar(10))




			declare @counter int = 1
			declare @CSref varchar(30)
			declare @Vol int

			while (@counter <= (select max(ID) from #ThrottleCounts))
			begin

			 set @Vol = (select ThrottleProportion from #ThrottleCounts where ID = @counter)
			 set @CSref = (select clientservicesref from #ThrottleCounts where ID = @counter)

			 insert into #FinalSelection 
			 select top (@Vol) fanid, clientservicesref
			 from #SelectionCategories
			 where
			 Clientservicesref = @CSref

			 set @counter = @counter + 1

			end

	Set @Step = @Step + 1
	End


If OBJECT_ID('Warehouse.Selections.TV001_TV020_PreSelection') Is Not Null Drop Table Warehouse.Selections.TV001_TV020_PreSelection
select fanid
	 , clientservicesref
into Warehouse.Selections.TV001_TV020_PreSelection
from #FinalSelection


If object_id('Warehouse.Selections.TV001_PreSelection') is not null drop table Warehouse.Selections.TV001_PreSelection
Select FanID
Into Warehouse.Selections.TV001_PreSelection
From Warehouse.Selections.TV001_TV020_PreSelection
Where clientservicesref = 'TV001'

END

