﻿-- =============================================
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


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	ConsumerCombinationID
		,BrandID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (2656,2657,3295,3244)

DECLARE @Date DATE = DATEADD(MONTH,-12,GETDATE())

IF OBJECT_ID('Sandbox.SamW.MonicaVinander050221') IS NOT NULL DROP TABLE Sandbox.SamW.MonicaVinander050221
SELECT	F.CINID
INTO Sandbox.SamW.MonicaVinander050221
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0 
AND		TranDate >= @Date

