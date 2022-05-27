﻿-- =============================================
SELECT CINID
		,FANID
INTO #FB
FROM	Relational.Customer C 
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID 
		,BrandName
		,B.BrandID
INTO #CC
FROM	Relational.ConsumerCombination CC
JOIN	Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	B.BrandID IN (1158,2617,2139,2484,2526)

CREATE CLUSTERED INDEX CIX_CCID ON #CC (ConsumerCombinationID)

DECLARE @OneYearAgo DATE = DATEADD(MONTH,-12,GETDATE())

IF OBJECT_ID('Sandbox.SamW.GoustoCompSteal060720') IS NOT NULL DROP TABLE Sandbox.SamW.GoustoCompSteal060720
SELECT	DISTINCT F.CINID, F.FanID
INTO Sandbox.SamW.GoustoCompSteal060720
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= @OneYearAgo