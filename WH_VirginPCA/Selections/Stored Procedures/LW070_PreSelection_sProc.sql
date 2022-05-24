-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-11>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[LW070_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID ,FanID
INTO #FB
FROM	Derived.Customer C
JOIN	Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	BrandName 
		,CC.BrandID
		,ConsumerCombinationID
INTO #CC
FROM	Trans.ConsumerCombination CC
JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN (246)


IF OBJECT_ID('tempdb..#shoppper') IS NOT NULL DROP TABLE #shoppper
SELECT DISTINCT ct.CINID
		,COUNT(CT.CINID) Txn
INTO	#shoppper
FROM	MIDI.ConsumerTransactionHolding ct
JOIN	#CC cc	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN	#FB fb	ON ct.CINID = fb.CINID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
AND		Amount > 0
GROUP BY ct.CINID


IF OBJECT_ID('Sandbox.rukank.LaithwaiteShopper') IS NOT NULL DROP TABLE Sandbox.rukank.LaithwaiteShopper
SELECT	F.CINID
INTO Sandbox.rukank.LaithwaiteShopper
FROM #shoppper F
WHERE Txn = 1
GROUP BY F.CINID


IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
SELECT	FanID
INTO #SegmentAssignment
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.rukank.LaithwaiteShopper cs
				WHERE fb.CINID = cs.CINID)If Object_ID('WH_Visa.Selections.LW070_PreSelection') Is Not Null Drop Table WH_Visa.Selections.LW070_PreSelectionSelect FanIDInto WH_Visa.Selections.LW070_PreSelectionFROM  #SEGMENTASSIGNMENTEND
