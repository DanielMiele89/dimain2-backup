-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-01-24>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.HS118_PreSelection_sProcASBEGIN
-- Get HS CCIDs
if object_id('tempdb..#CCHSs') is not null drop table #CCHSs
select ConsumerCombinationID, BrandID
into #CCHSs
from relational.consumercombination
where
BrandID in (188)

create clustered index INX on #CCHSs(consumercombinationID)

-- Get HS stats
declare @Today date, @YearAgo date, @6MonthsAgo date
set @Today = getdate()
set @YearAgo = dateadd(year,-1,@Today)
set @6MonthsAgo = dateadd(MONTH,-6,@Today)


if object_id('tempdb..#HScustomers') is not null drop table #HScustomers
select c.FanID, cc.Brandid,
case when max(ct.TranDate) < @6MonthsAgo then 1 else 0 end as HSlapser,

sum(ct.Amount) as HSsales,
count(1) as HStxs,
avg(ct.amount) as ATV

into #HScustomers
from #CCHSs cc
inner join relational.ConsumerTransaction ct on ct.ConsumerCombinationID = cc.ConsumerCombinationID
inner join relational.cinlist cl on cl.CINid = ct.CINID
inner join Relational.customer c on c.SourceUID = cl.CIN
where
trandate between @YearAgo and @Today 
and ct.amount > 0
group by c.FanID, cc.Brandid


-- Get the counts per definitions based on above
-- HS
select FanID,
case 
when c.HSlapser = 0 and c.HSsales > 0 and c.HSsales < 25 then 'Existing - Low'
when c.HSlapser = 0 and c.HSsales >= 25 and c.HSsales < 60 then 'Existing - Medium'
when c.HSlapser = 0 and c.HSsales >= 60 and c.HSsales < 220 then 'Existing - High'
when c.HSlapser = 0 and c.HSsales >= 220 then 'Existing - VIP'
when c.HSlapser = 0 then 'Existing - Error'

when c.HSlapser = 1 and c.HSsales > 0 and c.HSsales < 25 then 'Lapsed - Low'
when c.HSlapser = 1 and c.HSsales >= 25 and c.HSsales < 55 then 'Lapsed - Medium'
when c.HSlapser = 1 and c.HSsales > 55 and c.HSsales < 170 then 'Lapsed - High'
when c.HSlapser = 1 and c.HSsales >= 170 then 'Lapsed - VIP'
when c.HSlapser = 1 then 'Lapsed - Error'
else 'Error' end as Category

into #HScusCat
from #HScustomers cIf Object_ID('Warehouse.Selections.HS118_PreSelection') Is Not Null Drop Table Warehouse.Selections.HS118_PreSelectionSelect FanIDInto Warehouse.Selections.HS118_PreSelectionFrom #HScusCatwhere Category LIKE '%Medium%'END