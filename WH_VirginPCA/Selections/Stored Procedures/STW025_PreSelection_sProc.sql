-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-07-24>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[STW025_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID ,FanID
INTO #FB
FROM	Warehouse.Relational.Customer C
JOIN	Warehouse.Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
--AND		SourceUID NOT IN (SELECT SourceUID FROM Warehouse.Staging.Customer_DuplicateSourceUID) 

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	BrandName 
		,CC.BrandID
		,ConsumerCombinationID
INTO #CC
FROM	Warehouse.Relational.ConsumerCombination CC
JOIN	Warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN (2648)


IF OBJECT_ID('tempdb..#shoppper') IS NOT NULL DROP TABLE #shoppper
SELECT DISTINCT ct.CINID
		,COUNT(CT.CINID) Txn
INTO	#shoppper
FROM	Warehouse.Relational.ConsumerTransaction_MyRewards ct
JOIN	#CC cc	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN	#FB fb	ON ct.CINID = fb.CINID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
		AND Amount > 0
GROUP BY ct.CINID


IF OBJECT_ID('Sandbox.rukank.STWCshopper') IS NOT NULL DROP TABLE Sandbox.rukank.STWCshopper
SELECT	F.CINID
INTO Sandbox.rukank.STWCshopper
FROM #shoppper F
WHERE Txn = 1
GROUP BY F.CINID


IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
SELECT	FanID
INTO #SegmentAssignment
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.rukank.STWCshopper cs
				WHERE fb.CINID = cs.CINID)
If Object_ID('Warehouse.Selections.STW025_PreSelection') Is Not Null Drop Table Warehouse.Selections.STW025_PreSelectionSelect FanIDInto Warehouse.Selections.STW025_PreSelectionFROM  #SEGMENTASSIGNMENTEND
