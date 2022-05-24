CREATE PROCEDURE [Selections].[PO040_PreSelection_sProc]
AS
BEGIN

------------------------------------------------------------------------------
--RBS
------------------------------------------------------------------------------
--IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
--SELECT	CINID, FanID
--INTO #FB
--FROM	Relational.Customer C
--JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
--WHERE	C.CurrentlyActive = 1
--AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 


--IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
--SELECT ConsumerCombinationID
--INTO #CC
--FROM	Relational.ConsumerCombination CC
--WHERE	BrandID IN (1891,886,1925,1926,2411) 

--IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
--SELECT	F.CINID
--INTO #Trans
--FROM	#FB F
--JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
--JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE	Amount > 0
--AND		TranDate >= DATEADD(MONTH,-30,GETDATE())
--GROUP BY F.CINID


--IF OBJECT_ID('Sandbox.RukanK.po_ferries_compsteal') IS NOT NULL DROP TABLE Sandbox.RukanK.po_ferries_compsteal
--SELECT	F.CINID
--INTO Sandbox.RukanK.po_ferries_compsteal
--FROM	#FB F
--JOIN	#Trans T ON F.CINID = T.CINID
----WHERE	F.CINID NOT IN (SELECT CINID FROM #MainTrans)
--GROUP BY F.CINID

------------------------------------------------------------------------------
--VIRGIN
------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO	#FB
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
--AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
INTO	#CC
FROM	WH_Virgin.trans.ConsumerCombination  CC
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
GROUP BY #Trans.[CINID]

IF OBJECT_ID('[WH_Virgin].[Selections].[PO040_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[PO040_PreSelection]
SELECT	[fb].[FanID]
INTO [WH_Virgin].[Selections].[PO040_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.po_ferries_compsteal_virgin sb
				WHERE fb.CINID = #FB.[sb].CINID)

END
