-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-05-03>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[BTS009_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	warehouse.Relational.Customer C
JOIN	warehouse.Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM warehouse.Staging.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO #CC
FROM	warehouse.Relational.ConsumerCombination CC
WHERE	BrandID IN (2644,2018,1567,1858,2662,2459,1569,2667,2839,2467,2179,2374,1634,1365,1458,2923,843,1568,2262,933,57,202,265,381,414)

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	#FB F
JOIN	warehouse.Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate >= DATEADD(MONTH,-12,GETDATE())
GROUP BY F.CINID


IF OBJECT_ID('tempdb..#CC_boots') IS NOT NULL DROP TABLE #CC_boots
SELECT ConsumerCombinationID
INTO #CC_boots
FROM	warehouse.Relational.ConsumerCombination CC
WHERE	BrandID IN (61)

IF OBJECT_ID('tempdb..#Trans_shoppers') IS NOT NULL DROP TABLE #Trans_shoppers
SELECT	F.CINID
INTO #Trans_shoppers
FROM	#FB F
JOIN	warehouse.Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC_boots C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate >= DATEADD(MONTH,-6,GETDATE())
GROUP BY F.CINID


IF OBJECT_ID('tempdb..#Trans_lapsed') IS NOT NULL DROP TABLE #Trans_lapsed
SELECT	F.CINID
INTO #Trans_lapsed
FROM	#FB F
JOIN	warehouse.Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC_boots C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate between DATEADD(MONTH,-12,GETDATE()) and  DATEADD(MONTH,-6,GETDATE())
GROUP BY F.CINID

IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
SELECT	FanID
INTO #SegmentAssignment
from #FB 
where cinid in (select CINID from #Trans_lapsed)
and cinid in (select CINID from #Trans)
and cinid not in (select cinid from #Trans_shoppers)INSERT INTO #SegmentAssignmentSELECT FanIDFROM Segmentation.Roc_Shopper_Segment_Members sgWHERE PartnerID = 4036AND EndDate IS NULLAND ShopperSegmentTypeID = 7AND EXISTS (SELECT 1			FROM #Trans hb			INNER JOIN [Relational].[CINList] cl				ON hb.CINID = cl.CINID			INNER JOIN [Relational].[Customer] cu				ON cl.CIN = cu.SourceUID			WHERE sg.FanID = cu.FanID)If Object_ID('Warehouse.Selections.BTS009_PreSelection') Is Not Null Drop Table Warehouse.Selections.BTS009_PreSelectionSelect FanIDInto Warehouse.Selections.BTS009_PreSelectionFROM  #SegmentAssignmentEND