-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-03-06>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.UO008_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (459,457)


IF OBJECT_ID('tempdb..#MainBrandCC') IS NOT NULL DROP TABLE #MainBrandCC
SELECT ConsumerCombinationID
INTO #MainBrandCC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (472)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate >= DATEADD(MONTH,-24,GETDATE())
GROUP BY F.CINID


IF OBJECT_ID('tempdb..#MainTrans') IS NOT NULL DROP TABLE #MainTrans
SELECT	F.CINID
INTO #MainTrans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#MainBrandCC C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate >= DATEADD(MONTH,-12,GETDATE())
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.SamW.UrbanOutfittersCompetitorSteal') IS NOT NULL DROP TABLE Sandbox.SamW.UrbanOutfittersCompetitorSteal
SELECT	F.CINID
INTO Sandbox.SamW.UrbanOutfittersCompetitorSteal
FROM	#FB F
JOIN	#Trans T 
	ON F.CINID = T.CINID
--WHERE	F.CINID NOT IN (SELECT CINID FROM #MainTrans)
GROUP BY F.CINID

If Object_ID('Warehouse.Selections.UO008_PreSelection') Is Not Null Drop Table Warehouse.Selections.UO008_PreSelectionSelect FanIDInto Warehouse.Selections.UO008_PreSelectionFROM  #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.SAMW.UrbanOutfittersCompetitorSteal sb				WHERE fb.CINID = sb.CINID)END