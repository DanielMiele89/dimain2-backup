-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-08-09>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE Procedure [Selections].[EC106_PreSelection_sProc]ASBEGIN

select CompetitorID, b.BrandName
into #competitors
from relational.BrandCompetitor bc
inner join relational.brand b on b.brandid = bc.CompetitorID
where
bc.BrandID = 1370




select cc.consumercombinationID, c.BrandName, c.CompetitorID
into #CCs
from Relational.consumercombination cc
inner join #competitors c on c.CompetitorID = cc.BrandID

create clustered index INX on #CCs(consumercombinationID)



declare @Today date = getdate()
declare @YearAgo date = dateadd(year, -1, @Today)

select ct.CINID, c.fanid, count(1) as TXs, avg(ct.amount) as Sales
into #Customers
from #CCs cc
inner join relational.ConsumerTransaction ct on ct.ConsumerCombinationID = cc.ConsumerCombinationID
inner join relational.cinlist cl on cl.CINID = ct.CINID
inner join Relational.customer c on c.sourceuid = cl.cin
where
ct.TranDate between @YearAgo and @Today
group by
ct.CINID, c.fanid



-- Get the ATF
--select avg(1.00*TXs), count(1), Avg(Sales), sum(sales)
--from #Customers
--where
--Txs >= 3
-- This is 2.33


If Object_ID('sandbox.gabor.EUR0014_Over3') Is Not Null Drop Table sandbox.gabor.EUR0014_Over3
select CINID, fanid
into sandbox.gabor.EUR0014_Over3
from #Customers
where
Txs >= 3If Object_ID('Warehouse.Selections.EC106_PreSelection') Is Not Null Drop Table Warehouse.Selections.EC106_PreSelectionSelect FanIDInto Warehouse.Selections.EC106_PreSelectionFrom sandbox.gabor.EUR0014_Over3END