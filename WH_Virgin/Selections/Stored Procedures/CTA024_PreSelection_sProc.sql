-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-06-25>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[CTA024_PreSelection_sProc]ASBEGIN
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	[CL].[CINID] ,[C].[FanID]
INTO #FB
FROM	Derived.Customer C
JOIN	Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		[C].[SourceUID] NOT IN (SELECT [Derived].[Customer_DuplicateSourceUID].[SourceUID] FROM Derived.Customer_DuplicateSourceUID) 

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	BrandName 
		,CC.BrandID
		,[CC].[ConsumerCombinationID]
INTO #CC
FROM	Trans.ConsumerCombination CC
JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN (101,75,354,914,407)


IF OBJECT_ID('tempdb..#shoppper_sow') IS NOT NULL DROP TABLE #shoppper_sow
SELECT DISTINCT ct.CINID
		,1.0 * (CAST(SUM(CASE WHEN BrandID = 101 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS CostaSoW
		,MAX(CASE WHEN BrandID = 101 AND TranDate >= DATEADD(MONTH,-6,GETDATE()) THEN 1 ELSE 0 END) CostaShopper
INTO	#shoppper_sow
FROM	Trans.ConsumerTransaction ct
JOIN	#CC cc	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN	#FB fb	ON ct.CINID = fb.CINID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
		AND Amount > 0
GROUP BY ct.CINID


-- shoppers - SOW - < 30%
IF OBJECT_ID('Sandbox.rukank.costa_sow30_VM') IS NOT NULL DROP TABLE Sandbox.rukank.costa_sow30_VM
SELECT	F.CINID
INTO Sandbox.rukank.costa_sow30_VM
FROM #shoppper_sow F
WHERE [F].[CostaShopper] = 1
AND [F].[CostaSoW] < 0.3
GROUP BY F.CINID
IF OBJECT_ID('tempdb..#AcquireLapsed') IS NOT NULL DROP TABLE #AcquireLapsedSELECT [sg].[FanID]INTO #AcquireLapsedFROM [Segmentation].[Roc_Shopper_Segment_Members] sgWHERE sg.PartnerID = 4781AND sg.EndDate IS NULLAND sg.ShopperSegmentTypeID IN (7, 8)
IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignmentSELECT [fb].[FanID]INTO #SegmentAssignmentFROM #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.rukank.costa_sow30_VM cs				WHERE fb.CINID = #FB.[cs].CINID)UNION ALLSELECT	#AcquireLapsed.[FanID]FROM #AcquireLapsedIf Object_ID('WH_Virgin.Selections.CTA024_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.CTA024_PreSelectionSelect [fb].[FanID]Into WH_Virgin.Selections.CTA024_PreSelectionFROM #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.rukank.costa_sow30_VM cs				WHERE fb.CINID = #FB.[cs].CINID)UNION ALLSELECT	#AcquireLapsed.[FanID]FROM #AcquireLapsedEND