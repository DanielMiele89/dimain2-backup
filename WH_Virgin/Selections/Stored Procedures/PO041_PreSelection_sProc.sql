CREATE PROCEDURE [Selections].[PO041_PreSelection_sProc]
AS
BEGIN

-------------------------------------------------------------------
--RBS
-----------------------------------------------------------------------

--IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
--SELECT	CINID	,FanID
--INTO #FB
--FROM	Relational.Customer C
--JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
--WHERE	C.CurrentlyActive = 1
--AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 

--IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
--SELECT ConsumerCombinationID
--INTO #CC
--FROM	Relational.ConsumerCombination CC
--join Relational.brand B on b.Brandid = cc.BrandID
--WHERE	sectorid = 49 

--IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
--SELECT	F.CINID
--INTO #Trans
--FROM	#FB F
--JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
--JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE	Amount > 0
--AND		TranDate >= DATEADD(MONTH,-24,GETDATE())
--GROUP BY F.CINID;

--SELECT	F.CINID
--INTO Sandbox.RukanK.po_ferries_compsteal_p2
--FROM	#FB F
--JOIN	#Trans T ON F.CINID = T.CINID
----WHERE	F.CINID NOT IN (SELECT CINID FROM #MainTrans)
--WHERE F.CINID NOT IN (SELECT CINID FROM Sandbox.RukanK.po_ferries_compsteal)
--GROUP BY F.CINID;


-------------------------------------------------------------------
--VIRGIN
-------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID		,FanID
INTO	#FB
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
--AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO	#CC
FROM	WH_Virgin.trans.ConsumerCombination  CC
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

IF OBJECT_ID('[WH_Virgin].[Selections].[PO041_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[PO041_PreSelection]
SELECT	FanID
INTO [WH_Virgin].[Selections].[PO041_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.BastienC.po_ferries_airlines_virgin sb
				WHERE fb.CINID = sb.CINID)

END
