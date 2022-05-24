-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure [Selections].[TR118_PreSelection_sProc]
AS
BEGIN

-- Get relevant BrandIDs and then their CCIDs
-- THIS IS NOW MODIFIED
IF OBJECT_ID('tempdb..#CC_MARKET') IS NOT NULL DROP TABLE #CC_MARKET
select ConsumerCombinationID, BrandID
into #CC_MARKET
from Warehouse.Relational.ConsumerCombination cc
where
BrandID in (1023, 1826, 1322, 1321, 1318, 1312, 1315, 1333, 2538, 1330, 1325, 1324, 1284, 2021, 2464, 1331, 1043, 1323, 1099, 1334, 1313, 1317, 918, 1404, 1320, 2539, 2538, 935, 1285, 1406, 1754, 1754, 1336, 1338, 1319, 1309, 1307, 2540)


create clustered index INX on #CC_MARKET(ConsumercombinationID)

-- Get Trainline CCIDs
if object_id('tempdb..#CC_TR') is not null drop table #CC_TR
select ConsumerCombinationID, brandid
into #CC_TR
from warehouse.relational.consumercombination cc
where
cc.brandid = 1023


-- II, Get customers of interest
if object_id('tempdb..#Selection3') is not null drop table #Selection3
select 
ct.CINID
, c.FanID
, case 
  when count(1) >= 4 and count(1) <= 11 then 'Medium'
  when count(1) >= 12 then 'High' 
  else 'Low' end as RailSectorSpend,
 case
  when sum(case when cc.BrandID = 1023 then ct.Amount else 0 end )/ sum(ct.Amount) = 0 then 'Pure Acqusition'
  when sum(case when cc.BrandID = 1023 then ct.Amount else 0 end )/ sum(ct.Amount) between 0.84 and 1 then 'High'
  when sum(case when cc.BrandID = 1023 then ct.Amount else 0 end )/ sum(ct.Amount) between 0.37 and 0.84 then 'Medium'
  when sum(case when cc.BrandID = 1023 then ct.Amount else 0 end )/ sum(ct.Amount) between 0 and 0.37 then 'Low'
  end as TrainlineSoW
  , case 
when c.region = 'South East' then 'South East'
when c.region in ('West Midlands', 'East Midlands') then 'Midlands'
else 'Other' end as GeoLoc
  
into #Selection3
from #CC_MARKET cc
inner join relational.consumertransaction_myrewards ct on ct.ConsumerCombinationID = cc.ConsumerCombinationID
inner join relational.cinlist cl on cl.CINID = ct.CINID
inner join Relational.customer c on c.SourceUID = cl.CIN
inner join mi.CustomerActivationPeriod cap on cap.fanid = c.FanID

where
ct.TranDate > dateadd(YEAR,-1,getdate())
and ct.amount > 0

and cap.ActivationStart <= getdate()
and (cap.ActivationEnd is null or cap.ActivationEnd > getdate())

group by
ct.CINID, c.FanID, case 
when c.region = 'South East' then 'South East'
when c.region in ('West Midlands', 'East Midlands') then 'Midlands'
else 'Other' end

create clustered index INX on #Selection3(CINID)


-- III, Because we have a changed acquire length of 24 months, we remove those from Pure acquisition who purchased in months 12-24
-- Get those who purchased at month 12-24.
if object_id('tempdb..#Spenders12to24') is not null drop table #Spenders12to24
select distinct ct.cinid, c.FanID
into #Spenders12to24
from #CC_TR cc
inner join relational.consumertransaction_myrewards ct on ct.ConsumerCombinationID = cc.ConsumerCombinationID
inner join relational.cinlist cl on cl.CINID = ct.CINID
inner join Relational.customer c on c.SourceUID = cl.CIN
where
ct.TranDate > dateadd(YEAR,-2,getdate())



-- Delete these people from Pure Acquisition
delete t
from #Selection3 t
inner join #Spenders12to24 a on a.CINID = t.CINID
where
t.TrainlineSoW = 'Pure Acqusition'


select s.RailSectorSpend, s.TrainlineSoW, count(*) as 'Customers'
from #Selection3 s 
group by 
s.RailSectorSpend, s.TrainlineSoW
order by
1,2


alter table #Selection3
add segment varchar(50) 

update s
set Segment = 
case 

when s.RailSectorSpend = 'High'  and s.TrainlineSoW = 'Pure Acqusition' and s.GeoLoc = 'Midlands' then '112.H-M'
when s.RailSectorSpend = 'High'  and s.TrainlineSoW = 'Pure Acqusition' and s.GeoLoc = 'Other'  then '113.H-O'
when s.RailSectorSpend = 'High'  and s.TrainlineSoW = 'Pure Acqusition' and s.GeoLoc = 'South East' then '114.H-SE'
when s.RailSectorSpend = 'Medium' and s.TrainlineSoW = 'Pure Acqusition' and s.GeoLoc = 'Midlands' then '115.M-M'
when s.RailSectorSpend = 'Medium' and s.TrainlineSoW = 'Pure Acqusition' and s.GeoLoc = 'Other'  then '116.M-O'
when s.RailSectorSpend = 'Medium' and s.TrainlineSoW = 'Pure Acqusition' and s.GeoLoc = 'South East' then '117.M-SE'
else 'NA' end

from #Selection3 s

	If Object_ID('Warehouse.Selections.TR_PreSelection') Is Not Null Drop table Warehouse.Selections.TR_PreSelection
	Select FanID
		 , Segment as Flag
	Into Warehouse.Selections.TR_PreSelection
	From #Selection3

	If Object_ID('Warehouse.Selections.TR118_PreSelection') Is Not Null Drop table Warehouse.Selections.TR118_PreSelection
	Select FanID
	Into Warehouse.Selections.TR118_PreSelection
	From Warehouse.Selections.TR_PreSelection
	Where Flag = '112.H-M'

END
