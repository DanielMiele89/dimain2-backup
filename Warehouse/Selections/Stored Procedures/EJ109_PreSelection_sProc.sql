-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-10-02>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE Procedure [Selections].[EJ109_PreSelection_sProc]ASBEGIN
-- Get EJ CCIDs
if object_id('tempdb..#CCEJs') is not null drop table #CCEJs
select ConsumerCombinationID, BrandID
into #CCEJs
from relational.consumercombination
where
BrandID in (142)

create clustered index INX on #CCEJs(consumercombinationID)





-- Get EJ stats
declare @Today date, @YearAgo date, @6MonthsAgo date
set @Today = Getdate()
set @YearAgo = dateadd(year,-1,@Today)
set @6MonthsAgo = dateadd(MONTH,-6,@Today)


if object_id('tempdb..#EJcustomers') is not null drop table #EJcustomers
select c.FanID, cc.Brandid,
case when max(ct.TranDate) < @6MonthsAgo then 1 else 0 end as EJlapser,

sum(ct.Amount) as EJsales,
count(1) as EJtxs,
avg(ct.amount) as ATV

into #EJcustomers
from #CCEJs cc
inner join relational.ConsumerTransaction ct on ct.ConsumerCombinationID = cc.ConsumerCombinationID
inner join relational.cinlist cl on cl.CINid = ct.CINID
inner join Relational.customer c on c.SourceUID = cl.CIN
where
trandate between @YearAgo and @Today 
and ct.amount > 0
group by c.FanID, cc.Brandid






-- Phase II.
-- Get the counts per definitions based on above
-- EJ
select FanID,
case 
when c.EJlapser = 0 and c.EJsales > 0 and c.EJsales < 55 then 'Existing - Low'
when c.EJlapser = 0 and c.EJsales >= 55 and c.EJsales < 140 then 'Existing - Medium'
when c.EJlapser = 0 and c.EJsales >= 140 and c.EJsales < 600 then 'Existing - High'
when c.EJlapser = 0 and c.EJsales >= 600 then 'Existing - VIP'
when c.EJlapser = 0 then 'Existing - Error'

when c.EJlapser = 1 and c.EJsales > 0 and c.EJsales < 55 then 'Lapsed - Low'
when c.EJlapser = 1 and c.EJsales >= 55 and c.EJsales < 140 then 'Lapsed - Medium'
when c.EJlapser = 1 and c.EJsales >= 140 and c.EJsales < 500 then 'Lapsed - High'
when c.EJlapser = 1 and c.EJsales >= 500 then 'Lapsed - VIP'
when c.EJlapser = 1 then 'Lapsed - Error'
else 'Error' end as Category

into #EJcusCat
from #EJcustomers c

If Object_ID('Warehouse.Selections.EJ109_PreSelection') Is Not Null Drop Table Warehouse.Selections.EJ109_PreSelectionSelect FanIDInto Warehouse.Selections.EJ109_PreSelectionFrom #EJcusCatwhere Category LIKE '%Low%'END