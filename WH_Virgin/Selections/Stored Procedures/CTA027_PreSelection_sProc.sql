﻿-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2021-06-25>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE PROCEDURE [Selections].[CTA027_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID,FanID
INTO	#FB
FROM	WH_Virgin.Derived.Customer C
LEFT JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT [Derived].[Customer_DuplicateSourceUID].[SourceUID] FROM Derived.Customer_DuplicateSourceUID) 
CREATE CLUSTERED INDEX ix_CINID on #FB(FANID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	CC.BrandID
		,[WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
INTO	#CC
FROM	WH_Virgin.trans.ConsumerCombination CC
WHERE	CC.BrandID IN (101,75,354,914,407)
CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
SELECT  ct.CINID
		,fb.FanID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 101 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS CostaSoW
		,MAX(CASE WHEN BrandID = 101 AND TranDate >= DATEADD(MONTH,-6,GETDATE()) THEN 1 ELSE 0 END) CostaShopper
INTO	#shoppper_sow
FROM	WH_Virgin.trans.consumertransaction ct
JOIN	#CC cc	ON #CC.[ct].ConsumerCombinationID = cc.ConsumerCombinationID
JOIN	#FB fb	ON ct.CINID = fb.CINID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
		AND Amount > 0
GROUP BY ct.CINID,fb.FanID
CREATE CLUSTERED INDEX ix_FanID on #shoppper_sow(FanID)


-- shoppers - SOW - < 30%
IF OBJECT_ID('Sandbox.rukank.VM_costa_sow30_15022022') IS NOT NULL DROP TABLE Sandbox.rukank.VM_costa_sow30_15022022
SELECT	f.CINID
INTO	Sandbox.rukank.VM_costa_sow30_15022022
FROM	#shoppper_sow F
WHERE	[F].[CostaShopper] = 1
		AND [F].[CostaSoW] < 0.3
GROUP BY F.CINID

IF OBJECT_ID('tempdb..#AcquireLapsed') IS NOT NULL DROP TABLE #AcquireLapsed
SELECT [sg].[FanID]
INTO #AcquireLapsed
FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
WHERE sg.PartnerID = 4781
AND sg.EndDate IS NULL
AND sg.ShopperSegmentTypeID IN (7, 8)

IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
SELECT [fb].[FanID]
INTO #SegmentAssignment
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.rukank.VM_costa_sow30_15022022 cs
				WHERE fb.CINID = #FB.[cs].CINID)
UNION ALL
SELECT	[al].[FanID]
FROM #AcquireLapsed al
WHERE EXISTS (	SELECT 1
				FROM #FB fb
				WHERE #FB.[al].FanID = fb.FanID)

If Object_ID('WH_Virgin.Selections.CTA027_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.CTA027_PreSelection
Select *
Into WH_Virgin.Selections.CTA027_PreSelection
FROM #SegmentAssignment


END