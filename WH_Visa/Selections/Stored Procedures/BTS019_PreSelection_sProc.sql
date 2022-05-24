-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-07-12>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[BTS019_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	[Derived].[Customer] C
JOIN	[Derived].[CINList] CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM [Derived].[Customer_DuplicateSourceUID]) 

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)
CREATE NONCLUSTERED INDEX IX_FanID ON #FB (FanID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO #CC
FROM	[Trans].[ConsumerCombination] CC
WHERE	BrandID IN (2644,2018,1567,1858,2662,2459,1569,2667,2839,2467,2179,2374,1634,1365,1458,2923,843,1568,2262,933,57,202,265,381,414)

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE_12 DATE = DATEADD(MONTH, -12, GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	#FB F
JOIN	[Trans].[ConsumerTransaction] CT ON F.CINID = CT.CINID
JOIN	#CC C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate >= @DATE_12
GROUP BY F.CINID


IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
SELECT	FanID
INTO #SegmentAssignment
from #FB 
where cinid in (select CINID from #Trans)If Object_ID('[WH_Visa].Selections.BTS019_PreSelection') Is Not Null Drop Table [WH_Visa].Selections.BTS019_PreSelectionSelect FanIDInto [WH_Visa].Selections.BTS019_PreSelectionFROM  #SegmentAssignmentEND