-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-04-18>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[GU027_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT CINID
		,FANID
INTO #FB
FROM	Relational.Customer C 
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)
CREATE NONCLUSTERED INDEX IX_FanID ON #FB (FanID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID 
		,BrandName
		,B.BrandID
INTO #CC
FROM	Relational.ConsumerCombination CC
JOIN	Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	B.BrandID IN (1158,2617,2139,2484,2526)

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE_12 DATE = DATEADD(MONTH, -12, GETDATE())

IF OBJECT_ID('Sandbox.SamW.GoustoCompSteal060720') IS NOT NULL DROP TABLE Sandbox.SamW.GoustoCompSteal060720
SELECT	DISTINCT F.CINID, F.FANID
INTO Sandbox.SamW.GoustoCompSteal060720
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON CT.CINID = F.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate >= @DATE_12If Object_ID('Warehouse.Selections.GU027_PreSelection') Is Not Null Drop Table Warehouse.Selections.GU027_PreSelectionSelect FanIDInto Warehouse.Selections.GU027_PreSelectionFROM  SANDBOX.SAMW.GOUSTOCOMPSTEAL060720END