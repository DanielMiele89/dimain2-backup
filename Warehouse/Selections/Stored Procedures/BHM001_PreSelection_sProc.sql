-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-05>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[BHM001_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
AND		Gender = 'M'

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)
CREATE NONCLUSTERED INDEX IX_FanID ON #FB (FanID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (24,187,2519,1243,505,472,303,2592,371,457)

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE DATE = DATEADD(MONTH,-24,GETDATE())


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate >= @DATE
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.RukanK.boohoo_compsteal_Male_10082021') IS NOT NULL DROP TABLE Sandbox.RukanK.boohoo_compsteal_Male_10082021
SELECT	CINID
INTO Sandbox.RukanK.boohoo_compsteal_Male_10082021
FROM	#Trans If Object_ID('Warehouse.Selections.BHM001_PreSelection') Is Not Null Drop Table Warehouse.Selections.BHM001_PreSelectionSelect FanIDInto Warehouse.Selections.BHM001_PreSelectionFROM  Relational.Customer cuWHERE EXISTS (	SELECT 1				FROM Sandbox.RukanK.boohoo_compsteal_Male_10082021 s				INNER JOIN Relational.CINList cl					ON s.CINID = cl.CINID				WHERE cu.SourceUID = cl.CIN)END