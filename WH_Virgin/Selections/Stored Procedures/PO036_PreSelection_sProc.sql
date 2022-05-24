﻿-- =============================================

--------------------------------------------------------------------------
--VIRGIN
--------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO	#FB
FROM	WH_Virgin.Derived.Customer C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
--AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO	#CC
FROM	WH_Virgin.trans.ConsumerCombination CC
join Warehouse.Relational.Brand b on cc.BrandID = b.BrandID
WHERE	SectorID IN (47,24)

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
select ct.cinid
	,sum(case when trandate >= '2020-03-23' then amount else 0 end) as during_lockdown
	,sum(case when trandate < '2020-03-23' then amount else 0 end) as before_lockdown
INTO #Trans
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB F ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
where trandate between '2019-03-23' and '2021-03-23'
and amount > 0
GROUP BY ct.CINID


IF OBJECT_ID('Sandbox.BastienC.p_oferries_wfh_virgin') IS NOT NULL DROP TABLE Sandbox.BastienC.p_oferries_wfh_virgin
SELECT	CINID
INTO Sandbox.BastienC.p_oferries_wfh_virgin
from #Trans
where cinid not in (select cinid from Sandbox.RukanK.po_ferries_compsteal_virgin)
and cinid not in (select cinid from Sandbox.bastienc.po_ferries_airlines_virgin)
GROUP BY CINID

