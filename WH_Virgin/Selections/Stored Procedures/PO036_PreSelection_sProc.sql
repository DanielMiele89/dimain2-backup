-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-05>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.PO036_PreSelection_sProcASBEGIN

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

If Object_ID('WH_Virgin.Selections.PO036_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.PO036_PreSelectionSelect FanIDInto WH_Virgin.Selections.PO036_PreSelectionFROM WH_Virgin.derived.Customer cuWHERE EXISTS (	SELECT 1				FROM WH_Virgin.derived.[CINList] cl				INNER JOIN Sandbox.BastienC.p_oferries_wfh_virgin fo					ON cl.CINID = fo.CINID				WHERE cu.SourceUID = cl.CIN)END