-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-05>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.PO035_PreSelection_sProcASBEGIN

-------------------------------------------------------------------
--VIRGIN
-------------------------------------------------------------------
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
WHERE	BrandID IN (665,374,66,137,686,680,617,901,2615,583)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB F ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -24, GETDATE())
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.bastienc.po_ferries_airlines_virgin') IS NOT NULL DROP TABLE Sandbox.BastienC.po_ferries_airlines_virgin
SELECT	CINID
INTO Sandbox.bastienc.po_ferries_airlines_virgin
FROM	#Trans 
where cinid not in (select cinid from Sandbox.RukanK.po_ferries_compsteal_virgin)
GROUP BY CINID
If Object_ID('WH_Virgin.Selections.PO035_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.PO035_PreSelectionSelect FanIDInto WH_Virgin.Selections.PO035_PreSelectionFROM WH_Virgin.derived.Customer cuWHERE EXISTS (	SELECT 1				FROM WH_Virgin.derived.[CINList] cl				INNER JOIN Sandbox.bastienc.po_ferries_airlines_virgin fo					ON cl.CINID = fo.CINID				WHERE cu.SourceUID = cl.CIN)END