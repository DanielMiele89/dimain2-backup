-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- History modified for perf ChrisM 20180308

-- Notes on usage:
-- The script requires the following fields:
-- 1. FanID
-- 2. GroupName (This is an indicator of different populations. There can be N populations input and the output will separate out groups with different GroupNames.)

-- =============================================
create PROCEDURE insightarchive.[CustomerProfiling_GG_UnderConstruction_07112018]
	(
		@Population VARCHAR(100)
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
/*	Population Selected:
	The 

*/
--------------------------------------------------------------------------------------------------------------------
-- START








--DECLARE @Population varchar(130) = '( select top 1000000 fanid, ''Mailed'' as GroupName from warehouse.relational.customer order by newid() )'
DECLARE @Today date = getdate()

--print @Population



-- I. Define your Population
IF OBJECT_ID('tempdb..#Pop') IS NOT NULL DROP TABLE #Pop
CREATE TABLE #Pop
	(
		FanID INT,
		CINID INT,
		GroupName varchar(50),
		Age INT
	)



insert into #Pop
EXEC		('	
				select f.ID, cl.cinid, p.GroupName, datediff(year, ' + @Today + ', f.DOB) as Age
				from slc_report.dbo.Fan f
				inner join warehouse.relational.cinlist cl on cl.CIN = f.sourceuid
				inner join ' + @Population + ' p on p.fanid = f.id
				where
				clubid in (132,138)
			')
CREATE CLUSTERED INDEX cix_CINID ON #Pop(CINID)
CREATE nonCLUSTERED INDEX ncix_FanID ON #Pop(Fanid)





--DECLARE @Today date = getdate()
DECLARE @YearAgo date = dateadd(year, -1, @Today)

-- Get total debit card spend
IF OBJECT_ID('tempdb..#TotalDebitSales') IS NOT NULL DROP TABLE #TotalDebitSales
select
p.GroupName,
sum(case when ct.IsOnline = 1 then ct.Amount else 0 end) as OnlinePercentage,
sum(case when InputModeID in (4,8) then ct.Amount else 0 end) as Contactless,
sum(ct.amount) as TotalDebitSales

into #TotalDebitSales
from Warehouse.Relational.ConsumerTransaction ct
inner join #Pop p on p.CINID = ct.CINID

where
ct.TranDate between @YearAgo and @Today

group by
p.GroupName





-- Construct consumercombination table
IF OBJECT_ID('tempdb..#CCs') IS NOT NULL DROP TABLE #CCs
select cc.ConsumerCombinationID, cc.BrandID, b.sectorID
into #CCs
from Warehouse.Relational.ConsumerCombination cc
inner join Warehouse.Relational.brand b on b.BrandID = cc.BrandID
where
SectorID in (17, 5, 3)

create clustered index INX on #CCs(ConsumerCombinationID, sectorID, brandID)





--DECLARE @Today date = getdate()
--DECLARE @YearAgo date = dateadd(year, -1, @Today)


-- Get total debit card spend
IF OBJECT_ID('tempdb..#TotalDebitSales_Sectors') IS NOT NULL DROP TABLE #TotalDebitSales_Sectors
select
p.GroupName,
cc.BrandID, cc.SectorID, sum(ct.amount) as Sales, count(distinct ct.cinid) as Spdrs, count(1) as Txs

into #TotalDebitSales_Sectors
from Warehouse.Relational.ConsumerTransaction ct
inner join #CCs cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
inner join #Pop p on p.cinid = ct.cinid
where
ct.TranDate between @YearAgo and @Today

group by
p.GroupName,
cc.BrandID, cc.SectorID



IF OBJECT_ID('tempdb..#Sectors_Pre') IS NOT NULL DROP TABLE #Sectors_Pre
select tds.GroupName, tds.SectorID, tds.BrandID, 
members as PopulationCount,
1.00 * Spdrs/members as ResponseRate, 1.00 * tds.Sales / case when ag.TotalSales = 0 then null else ag.TotalSales end as SoW, 
tds.Sales,
tds.Txs,
row_number() over (partition by tds.sectorid order by Sales desc) as Rank
into #Sectors_Pre
from #TotalDebitSales_Sectors tds
inner join	(
	select GroupName, sectorid, sum(Sales) as TotalSales
	from #TotalDebitSales_Sectors
	group by
	GroupName, sectorid	) ag on ag.GroupName = tds.GroupName
							and ag.sectorID = tds.SectorID
inner join (select GroupName, count(1) as members from #Pop group by GroupName) pop on pop.GroupName = tds.GroupName





-- Logins and EmailOpens
-- Get weblogins
IF OBJECT_ID('tempdb..#Weblogins') IS NOT NULL DROP TABLE #Weblogins
Select FanID, count(distinct cast(trackdate as date)) as weblogins
Into #Weblogins
From warehouse.relational.WebLogins as wl
Where 
wl.trackdate between @YearAgo and @Today
group by 
FanID



-- Get Email Opens
IF OBJECT_ID('tempdb..#EmailOpens') IS NOT NULL DROP TABLE #EmailOpens
Select FanID, count(distinct ec.CampaignKey) as EmailOpens
into #EmailOpens
From warehouse.relational.CampaignLionSendIDs as cls -- List of campaign emails
inner join warehouse.relational.emailevent as ee -- list of events
		on cls.CampaignKey = ee.CampaignKey
inner join (select campaignkey, CampaignName from warehouse.relational.EmailCampaign where campaignname like '%Newsletter%') ec on ec.CampaignKey = ee.CampaignKey
Where  ee.EmailEventCodeID in (1301 -- Email Open
								,605 -- Link Click
								) 
and ee.EventDate between @YearAgo and @Today
group by 
FanID








--------------------------------------------------------
-- Output
--------------------------------------------------------


-- I, Output GeoDems
select p.GroupName,
CASE  
		WHEN c.AgeCurrent IS NULL or c.AgeCurrent >= 100 THEN '99. Unknown'
		WHEN c.AgeCurrent < 20 THEN '01. Under 20'
		WHEN c.AgeCurrent BETWEEN 20 AND 29 THEN '02. 20 to 29'
		WHEN c.AgeCurrent BETWEEN 30 AND 34 THEN '03. 30 to 34'
		WHEN c.AgeCurrent BETWEEN 35 AND 39 THEN '04. 35 to 39'
		WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '05. 40 to 49'
		WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '06. 50 to 59'
		WHEN c.AgeCurrent BETWEEN 60 AND 69 THEN '07. 60 to 69'
		WHEN c.AgeCurrent >= 70 THEN '08. 70+' 
END as Age_Group, 
case when c.Gender = 'F' then 'Female' when c.Gender = 'M' then 'Male' else 'Unknown' end as Gender,
ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO_CODE_GRP,
c.Region, count(1) as Customers

from #Pop p 
left join Warehouse.Relational.Customer c on c.fanid = p.FanID
Left Join Warehouse.Relational.CAMEO cam with (nolock)  on cam.postcode = c.postcode
Left Join Warehouse.Relational.CAMEO_CODE_GROUP camG with (nolock)  on camG.CAMEO_CODE_GROUP = cam.CAMEO_CODE_GROUP
group by
p.GroupName,
CASE  
	WHEN c.AgeCurrent IS NULL or c.AgeCurrent >= 100 THEN '99. Unknown'
	WHEN c.AgeCurrent < 20 THEN '01. Under 20'
	WHEN c.AgeCurrent BETWEEN 20 AND 29 THEN '02. 20 to 29'
	WHEN c.AgeCurrent BETWEEN 30 AND 34 THEN '03. 30 to 34'
	WHEN c.AgeCurrent BETWEEN 35 AND 39 THEN '04. 35 to 39'
	WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '05. 40 to 49'
	WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '06. 50 to 59'
	WHEN c.AgeCurrent BETWEEN 60 AND 69 THEN '07. 60 to 69'
	WHEN c.AgeCurrent >= 70 THEN '08. 70+' 
END, 
case when c.Gender = 'F' then 'Female' when c.Gender = 'M' then 'Male' else 'Unknown' end,
ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown'),
c.Region




-- II, Debit card usage
select 
tds.GroupName,
totalcus.Customers,
tds.TotalDebitSales,
1.00 * tds.OnlinePercentage / tds.TotalDebitSales as OnlinePercentage, 
1.00 * tds.Contactless / tds.TotalDebitSales as ContactlessPercentage,
1.00 * fashion.Sales / tds.TotalDebitSales as FashionPercentage, 
1.00 * grocery.Sales / tds.TotalDebitSales as GroceryPercentage, 
1.00 * restaurant.Sales / tds.TotalDebitSales as RestaurantPercentage

from #TotalDebitSales tds
inner join	(select GroupName, sum(Sales) as Sales
			 from #Sectors_Pre
			 where
			 SectorID = 5
			 group by
			 GroupName) fashion on tds.GroupName = fashion.GroupName
inner join	(select GroupName, sum(Sales) as Sales
			 from #Sectors_Pre
			 where
			 SectorID = 3
			 group by
			 GroupName) grocery on tds.GroupName = fashion.GroupName
inner join	(select GroupName, sum(Sales) as Sales
			 from #Sectors_Pre
			 where
			 SectorID = 17
			 group by
			 GroupName) restaurant on tds.GroupName = fashion.GroupName
inner join	(select GroupName, count(1) as Customers
			 from #Pop
			 group by
			 GroupName) totalcus on tds.GroupName = totalcus.GroupName





select
GroupName, SectorName, PopulationCount, cast(BrandName as varchar(40)), cast(Rank as varchar(40)), ResponseRate,
sum(Sales)/sum(Txs) as ATV,
case when BrandName = 'Other' then 'Other' else cast(Txs*1.00/cast(cast(ResponseRate as float) * PopulationCount as int) as varchar(30)) end as ATF,
sum(SoW) as Sow,
sum(Sales) as Sales

from (
	select 
	GroupName, PopulationCount,
	bs.SectorName, Sales, Txs, SoW,
	case when Rank > 10 then 'Other' else b.BrandName end as BrandName,
	case when Rank > 10 then 'Other' else cast(Rank as varchar(40)) end as Rank,
	case when Rank > 10 then 'Other' else cast(ResponseRate as varchar(40)) end as ResponseRate

	from #Sectors_Pre p
	inner join warehouse.Relational.BrandSector bs on bs.SectorID = p.SectorID
	inner join Warehouse.Relational.brand b on b.BrandID = p.BrandID
) ag

group by
GroupName, PopulationCount, SectorName, cast(BrandName as varchar(40)), cast(Rank as varchar(40)), ResponseRate,
case when BrandName = 'Other' then 'Other' else cast(Txs*1.00/cast(cast(ResponseRate as float) * PopulationCount as int) as varchar(30)) end

order by
1,2,5 desc




-- Engagement
-- Get weblogins
IF OBJECT_ID('tempdb..#Engagement') IS NOT NULL DROP TABLE #Engagement
select 
p.FanID as FanID, 
isnull(weblogins, 0) as WLs,
isnull(EmailOpens, 0) as EOs

into #Engagement
from #Pop p
left join #EmailOpens eo on eo.FanID = p.FanID
left join #Weblogins wl on p.FanID = wl.FanID




select 
case 
when EOs = 0 then '1. No EmailOpens'
when EOs between 1 and 2 then '2. 1-2 EmailOpens'
when EOs between 3 and 5 then '3. 3-5 EmailOpens'
when EOs between 6 and 10 then '4. 6-10 EmailOpens'
when EOs > 10 then '5. More than 10 EmailOpens'
else 'Error' end as EOs,
case 
when WLs = 0 then '1. No EmailOpens'
when WLs between 1 and 2 then '2. 1-2 EmailOpens'
when WLs between 3 and 5 then '3. 3-5 EmailOpens'
when WLs between 6 and 10 then '4. 6-10 EmailOpens'
when WLs > 10 then '5. More than 10 EmailOpens'
else 'Error' end as WLs, count(1) as Customers

from #Engagement
group by
case 
when EOs = 0 then '1. No EmailOpens'
when EOs between 1 and 2 then '2. 1-2 EmailOpens'
when EOs between 3 and 5 then '3. 3-5 EmailOpens'
when EOs between 6 and 10 then '4. 6-10 EmailOpens'
when EOs > 10 then '5. More than 10 EmailOpens'
else 'Error' end,
case 
when WLs = 0 then '1. No EmailOpens'
when WLs between 1 and 2 then '2. 1-2 EmailOpens'
when WLs between 3 and 5 then '3. 3-5 EmailOpens'
when WLs between 6 and 10 then '4. 6-10 EmailOpens'
when WLs > 10 then '5. More than 10 EmailOpens'
else 'Error' end













END


