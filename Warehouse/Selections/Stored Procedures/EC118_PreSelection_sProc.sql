﻿-- =============================================
SELECT	CINID
		,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	ConsumerCombinationID
INTO #CC
FROM	Relational.ConsumerCombination
WHERE	BrandID = 27

DECLARE @Date DATE = DATEADD(MONTH,-24,GETDATE())

IF OBJECT_ID('Sandbox.SamW.EuropcarAVISSteal241120') IS NOT NULL DROP TABLE Sandbox.SamW.EuropcarAVISSteal241120
SELECT	F.CINID
INTO Sandbox.SamW.EuropcarAVISSteal241120
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= @Date
