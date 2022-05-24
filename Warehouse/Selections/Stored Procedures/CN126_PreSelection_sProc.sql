-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-11-13>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.CN126_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT CINID
		,FANID
INTO #FB
FROM	Relational.Customer C 
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT DISTINCT SourceUID FROM Staging.Customer_DuplicateSourceUID)

IF OBJECT_ID('tempdb..#CompetitorSteal') IS NOT NULL DROP TABLE #CompetitorSteal
SELECT DISTINCT CTMR.CINID
INTO #CompetitorSteal
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CTMR ON CTMR.CINID = F.CINID
JOIN	Relational.ConsumerCombination CC ON CC.ConsumerCombinationID = CTMR.ConsumerCombinationID
WHERE CC.BrandID IN (1578,407,3026)
AND		TranDate >= DATEADD(MONTH, -6,GETDATE())

IF OBJECT_ID('Sandbox.SamW.CaffeNeroCovidCompSteal') IS NOT NULL DROP TABLE Sandbox.SamW.CaffeNeroCovidCompSteal
SELECT	F.CINID
		,FANID
INTO Sandbox.SamW.CaffeNeroCovidCompSteal
FROM	#FB F 
JOIN	#CompetitorSteal C ON C.CINID = F.CINIDIf Object_ID('Warehouse.Selections.CN126_PreSelection') Is Not Null Drop Table Warehouse.Selections.CN126_PreSelectionSelect FanIDInto Warehouse.Selections.CN126_PreSelectionFROM  SANDBOX.SAMW.CaffeNeroCovidCompStealEND