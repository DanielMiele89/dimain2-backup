-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-06-25>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[TT014_PreSelection_sProc]ASBEGIN--SELECT *
--FROM Relational.Brand
--WHERE BrandName LIKE '%ODP%'


IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)
CREATE NONCLUSTERED INDEX IX_FanID ON #FB (FanID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	ConsumerCombinationID
		,BrandID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (2862,1714,1629,376,1711,83,2850,1709,856,485,2525,232,1074,1725,232,2791,105,2468,167,485,1891,1048,56,247,199,107,1945,833,1458,480,253,396,1626,485,12,3039,1523,2837,2743)

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

IF OBJECT_ID('tempdb..#WaitroseCC') IS NOT NULL DROP TABLE #WaitroseCC
SELECT	ConsumerCombinationID
INTO #WaitroseCC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID = 485

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #WaitroseCC (ConsumerCombinationID)

IF OBJECT_ID('tempdb..#WCustomers') IS NOT NULL DROP TABLE #WCustomers
SELECT	f.CINID
INTO #WCustomers
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#WaitroseCC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
GROUP BY F.CINID

CREATE CLUSTERED INDEX CIX_CINID ON #WCustomers (CINID)

--IF OBJECT_ID('tempdb..#NonCC') IS NOT NULL DROP TABLE #NonCC
--SELECT	ConsumerCombinationID
--		,BrandID
--INTO #NonCC
--FROM	Relational.ConsumerCombination CC
--WHERE	BrandID IN (2862,1714,1629,376,1711,83,2850,1709,856,2525,232,1074,1725,232,2791,105,2468,167,485,1891,1048,56,247,199,107,1945,833,1458,480,253,396,1626,485,12,3039,1523,2837,2743)

--CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #NonCC (ConsumerCombinationID)


--IF OBJECT_ID('tempdb..#WTrans') IS NOT NULL DROP TABLE #WTrans
--SELECT	COUNT(DISTINCT F.CINID) Customers
--INTO #WTrans
--FROM	#FB F
--JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
--JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE	TranDate >= DATEADD(MONTH,-3,GETDATE())

IF OBJECT_ID('tempdb..#TelegraphCC') IS NOT NULL DROP TABLE #TelegraphCC
SELECT	ConsumerCombinationID
INTO #TelegraphCC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID = 1628

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #TelegraphCC (ConsumerCombinationID)

DECLARE @DATE_6 DATE = DATEADD(MONTH, -6, GETDATE())

IF OBJECT_ID('tempdb..#TelegraphTrans') IS NOT NULL DROP TABLE #TelegraphTrans
SELECT f.CINID
INTO #TelegraphTrans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#TelegraphCC CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= @DATE_6
AND		Amount > 0
GROUP BY F.CINID

CREATE CLUSTERED INDEX CIX_CINID ON #TelegraphTrans (CINID)

DECLARE @DATE_3 DATE = DATEADD(MONTH, -3, GETDATE())

IF OBJECT_ID('Sandbox.SamW.Telegraph050221') IS NOT NULL DROP TABLE Sandbox.SamW.Telegraph050221
SELECT	F.CINID
INTO Sandbox.SamW.Telegraph050221
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= @DATE_3
AND		F.CINID NOT IN (SELECT CINID FROM #TelegraphTrans)
AND		F.CINID NOT IN (SELECT CINID FROM #WCustomers)
AND		Amount > 0
GROUP BY F.CINIDIf Object_ID('Warehouse.Selections.TT014_PreSelection') Is Not Null Drop Table Warehouse.Selections.TT014_PreSelectionSelect FanIDInto Warehouse.Selections.TT014_PreSelectionFROM #FB fbWHERE EXISTS (	SELECT 1				FROM SANDBOX.SAMW.TELEGRAPH050221 t				WHERE fb.CINID = t.CINID)END