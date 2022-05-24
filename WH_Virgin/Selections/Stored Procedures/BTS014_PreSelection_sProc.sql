-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-21>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.BTS014_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	WH_Virgin.Derived.Customer C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM WH_Virgin.Derived.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT [WH_Virgin].[Trans].[ConsumerCombination].[ConsumerCombinationID]
INTO #CC
FROM	WH_Virgin.Trans.ConsumerCombination CC
WHERE	[WH_Virgin].[Trans].[ConsumerCombination].[BrandID] IN (2644,2018,1567,1858,2662,2459,1569,2667,2839,2467,2179,2374,1634,1365,1458,2923,843,1568,2262,933,57,202,265,381,414)

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	#FB F
JOIN	WH_Virgin.Trans.ConsumerTransaction CT ON F.CINID = #FB.[CT].CINID
JOIN	#CC C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate >= DATEADD(MONTH,-12,GETDATE())
GROUP BY F.CINID


IF OBJECT_ID('tempdb..#CC_boots') IS NOT NULL DROP TABLE #CC_boots
SELECT [WH_Virgin].[Trans].[ConsumerCombination].[ConsumerCombinationID]
INTO #CC_boots
FROM	WH_Virgin.Trans.ConsumerCombination CC
WHERE	[WH_Virgin].[Trans].[ConsumerCombination].[BrandID] IN (61)

IF OBJECT_ID('tempdb..#Trans_shoppers') IS NOT NULL DROP TABLE #Trans_shoppers
SELECT	F.CINID
INTO #Trans_shoppers
FROM	#FB F
JOIN	WH_Virgin.Trans.ConsumerTransaction CT ON F.CINID = #FB.[CT].CINID
JOIN	#CC_boots C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND Amount <> 9.35
AND		TranDate >= DATEADD(MONTH,-6,GETDATE())
GROUP BY F.CINID


IF OBJECT_ID('tempdb..#Trans_lapsed') IS NOT NULL DROP TABLE #Trans_lapsed
SELECT	F.CINID
INTO #Trans_lapsed
FROM	#FB F
JOIN	WH_Virgin.Trans.ConsumerTransaction CT ON F.CINID = #FB.[CT].CINID
JOIN	#CC_boots C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND Amount <> 9.35
AND		TranDate between DATEADD(MONTH,-12,GETDATE()) and DATEADD(MONTH,-6,GETDATE())
GROUP BY F.CINID

If Object_ID('WH_Virgin.Selections.BTS014_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.BTS014_PreSelectionSelect #FB.[FanID]Into WH_Virgin.Selections.BTS014_PreSelection
from #FB 
where #FB.[CINID] in (select #Trans_lapsed.[CINID] from #Trans_lapsed)
and #FB.[CINID] not in (select #Trans_shoppers.[CINID] from #Trans_shoppers)END