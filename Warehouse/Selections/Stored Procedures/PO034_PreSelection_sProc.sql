-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-05>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[PO034_PreSelection_sProc]ASBEGIN------------------------------------------------------------------------------
--RBS
------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)
CREATE NONCLUSTERED INDEX IX_FanID ON #FB (FanID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (1891,886,1925,1926,2411) 

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE_30 DATE = DATEADD(MONTH, -30, GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate >= @DATE_30
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.RukanK.po_ferries_compsteal') IS NOT NULL DROP TABLE Sandbox.RukanK.po_ferries_compsteal
SELECT	F.CINID
INTO Sandbox.RukanK.po_ferries_compsteal
FROM	#FB F
JOIN	#Trans T ON F.CINID = T.CINID
--WHERE	F.CINID NOT IN (SELECT CINID FROM #MainTrans)
GROUP BY F.CINIDIf Object_ID('Warehouse.Selections.PO034_PreSelection') Is Not Null Drop Table Warehouse.Selections.PO034_PreSelectionSelect FanIDInto Warehouse.Selections.PO034_PreSelectionFROM Relational.Customer cuWHERE EXISTS (	SELECT 1				FROM [Relational].[CINList] cl				INNER JOIN Sandbox.RukanK.po_ferries_compsteal fo					ON cl.CINID = fo.CINID				WHERE cu.SourceUID = cl.CIN)END