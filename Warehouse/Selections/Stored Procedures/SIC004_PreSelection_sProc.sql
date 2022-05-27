﻿-- =============================================
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	C.FanID
		,CINID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE C.CurrentlyActive = 1
	AND SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
CREATE CLUSTERED INDEX ix_FanID on #FB(FANID)


IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT	ConsumerCombinationID
		,CC.BrandID
		,BrandName
INTO #CCIDs
FROM Relational.ConsumerCombination cc WITH (NOLOCK)
JOIN Relational.Brand B ON B.BrandID = CC.BrandID
WHERE CC.BrandID = 2526
CREATE CLUSTERED INDEX CIX_CCID_CCID ON #CCIDs (ConsumerCombinationID)

IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
SELECT	F.CINID
INTO #Customers
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CCIDs C ON CT.ConsumerCombinationID = C.ConsumerCombinationID
GROUP BY F.CINID

IF OBJECT_ID('tempdb..#UnderSpend') IS NOT NULL DROP TABLE #UnderSpend
SELECT	F.CINID
INTO #UnderSpend
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#CCIDs C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
AND		Amount > 9.99
GROUP BY F.CINID

IF OBJECT_ID('Sandbox.SamW.SimplyCook020221') IS NOT NULL DROP TABLE Sandbox.SamW.SimplyCook020221
SELECT F.CINID
INTO Sandbox.SamW.SimplyCook020221
FROM #FB F
WHERE F.CINID NOT IN (SELECT CINID FROM #Customers)
OR F.CINID NOT IN (SELECT CINID FROM #UnderSpend)