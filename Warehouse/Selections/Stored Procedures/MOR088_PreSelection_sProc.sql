-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-03-06>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.MOR088_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	ConsumerCombinationID
INTO #CC
FROM	Relational.ConsumerCombination
WHERE	BrandID = 292

IF OBJECT_ID('tempdb..#LS') IS NOT NULL DROP TABLE #LS
SELECT	F.CINID
INTO #LS
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0 
AND		TranDate >= DATEADD(MONTH,-6,'2021-01-01')
AND		TranDate < '2021-01-01'
GROUP BY F.CINID

IF OBJECT_ID('tempdb..#Acquired') IS NOT NULL DROP TABLE #Acquired
SELECT	F.CINID
		,COUNT(*) Transactions
INTO #Acquired
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0 
AND		TranDate >= '2021-01-01'
AND		F.CINID NOT IN (SELECT CINID FROM #LS)
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.SamW.MorrisonsNursery030321') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsNursery030321
SELECT	CINID
INTO Sandbox.SamW.MorrisonsNursery030321
FROM	#Acquired
WHERE	Transactions = 1
GROUP BY CINID
If Object_ID('Warehouse.Selections.MOR088_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR088_PreSelectionSelect FanIDInto Warehouse.Selections.MOR088_PreSelectionFROM  #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.SAMW.MorrisonsNursery030321 sb				WHERE fb.CINID = sb.CINID)END