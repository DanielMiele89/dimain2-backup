-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-05>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.PO034_PreSelection_sProcASBEGIN

------------------------------------------------------------------------------
--VIRGIN
------------------------------------------------------------------------------

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
SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
INTO	#CC
FROM	WH_Virgin.trans.ConsumerCombination CC
WHERE	[WH_Virgin].[trans].[ConsumerCombination].[BrandID] IN (1891,886,1925,1926,2411)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB F ON F.CINID = #FB.[CT].CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -30, GETDATE())
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.RukanK.po_ferries_compsteal_virgin') IS NOT NULL DROP TABLE Sandbox.RukanK.po_ferries_compsteal_virgin
SELECT	#Trans.[CINID]
INTO Sandbox.RukanK.po_ferries_compsteal_virgin
FROM	#Trans 
GROUP BY #Trans.[CINID]If Object_ID('WH_Virgin.Selections.PO034_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.PO034_PreSelectionSelect [WH_Virgin].[derived].[Customer].[FanID]Into WH_Virgin.Selections.PO034_PreSelectionFROM WH_Virgin.derived.Customer cuWHERE EXISTS (	SELECT 1				FROM WH_Virgin.derived.[CINList] cl				INNER JOIN SANDBOX.RUKANK.PO_FERRIES_COMPSTEAL_VIRGIN fo					ON cl.CINID = fo.CINID				WHERE cu.SourceUID = cl.CIN)END