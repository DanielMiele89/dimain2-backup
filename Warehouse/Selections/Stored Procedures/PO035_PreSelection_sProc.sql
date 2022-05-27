﻿-- =============================================
--RBS
-----------------------------------------------------------------------

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
SELECT ConsumerCombinationID
INTO #CC
FROM	Relational.ConsumerCombination CC
join Relational.brand B on b.Brandid = cc.BrandID
WHERE	sectorid = 49 

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE_24 DATE = DATEADD(MONTH, -24, GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate >= @DATE_24
GROUP BY F.CINID;

If Object_ID('Sandbox.RukanK.po_ferries_compsteal_p2') Is Not Null Drop Table Sandbox.RukanK.po_ferries_compsteal_p2
INTO Sandbox.RukanK.po_ferries_compsteal_p2
FROM	#FB F
JOIN	#Trans T ON F.CINID = T.CINID
--WHERE	F.CINID NOT IN (SELECT CINID FROM #MainTrans)
WHERE F.CINID NOT IN (SELECT CINID FROM Sandbox.RukanK.po_ferries_compsteal)
GROUP BY F.CINID;