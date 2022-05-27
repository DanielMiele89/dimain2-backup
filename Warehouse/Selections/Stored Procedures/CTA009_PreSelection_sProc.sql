-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-12-22>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.CTA009_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FANID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	BrandName
		,CC.BrandID
		,ConsumerCombinationID
INTO #CC
FROM	Relational.ConsumerCombination CC
JOIN	Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN (101,75,354,914,407)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
		,FANID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 101 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS CostaSoW
		,MAX(CASE WHEN BrandID = 101 AND TranDate >= DATEADD(MONTH,-6,GETDATE()) THEN 1 ELSE 0 END) CostaShopper
INTO #Trans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
GROUP BY F.CINID
		,FANID


IF OBJECT_ID('Sandbox.SamW.CostaLessThan30SoW180820') IS NOT NULL DROP TABLE Sandbox.SamW.CostaLessThan30SoW180820
SELECT	CINID
		,FANID
INTO Sandbox.SamW.CostaLessThan30SoW180820
FROM	#Trans
WHERE CostaSoW < 0.3
AND		CostaShopper = 1

--IF OBJECT_ID('Sandbox.SamW.Costa30to60SoW180820') IS NOT NULL DROP TABLE Sandbox.SamW.Costa30to60SoW180820
--SELECT	CINID
--		,FANID
--INTO Sandbox.SamW.Costa30to60SoW180820
--FROM	#Trans
--WHERE	CostaSoW >= 0.3
--AND		CostaSoW < 0.6
--AND		CostaShopper = 1

--IF OBJECT_ID('Sandbox.SamW.Costa60to90SoW180820') IS NOT NULL DROP TABLE Sandbox.SamW.Costa60to90SoW180820
--SELECT	CINID
--		,FANID
--INTO Sandbox.SamW.Costa60to90SoW180820
--FROM	#Trans
--WHERE	CostaSoW >= 0.6
--AND		CostaSoW < 0.9
--AND		CostaShopper = 1
If Object_ID('Warehouse.Selections.CTA009_PreSelection') Is Not Null Drop Table Warehouse.Selections.CTA009_PreSelectionSelect FanIDInto Warehouse.Selections.CTA009_PreSelectionFROM  Sandbox.SamW.CostaLessThan30SoW180820END