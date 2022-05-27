﻿-- =============================================
--RBS
--------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
select cc.*
into #cc
from Warehouse.Relational.ConsumerCombination cc
join Warehouse.Relational.Brand b on cc.BrandID = b.BrandID
where SectorID in (47,24) -- transportation and petrol

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)


IF OBJECT_ID('tempdb..#temp1') IS NOT NULL DROP TABLE #temp1
select cinid
	,sum(case when trandate >= '2020-03-23' then amount else 0 end) as during_lockdown
	,sum(case when trandate < '2020-03-23' then amount else 0 end) as before_lockdown
into #temp1
from Warehouse.Relational.ConsumerTransaction_MyRewards ct
join #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
where trandate between '2019-03-23' and '2021-03-23'
and amount > 0
group by cinid
	,case when trandate > '2020-03-23' then 1 else 0 end 


IF OBJECT_ID('Sandbox.BastienC.p_oferries_wfh') IS NOT NULL DROP TABLE Sandbox.BastienC.p_oferries_wfh
select cinid
into Sandbox.BastienC.p_oferries_wfh
from #temp1 
where during_lockdown <200 and before_lockdown > 400
and CINID NOT IN (SELECT CINID FROM Sandbox.RukanK.po_ferries_compsteal)
and CINID NOT IN (SELECT CINID FROM Sandbox.RukanK.po_ferries_compsteal_p2)
