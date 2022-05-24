
CREATE PROCEDURE [Selections].[BTS021_PreSelection_sProc] 

AS  
BEGIN     IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	WH_Virgin.Derived.Customer C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
		


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
INTO #CC
FROM	WH_Virgin.trans.ConsumerCombination CC
WHERE	[WH_Virgin].[trans].[ConsumerCombination].[BrandID] IN (2644,2018,1567,1858,2662,2459,1569,2667,2839,2467,2179,2374,1634,1365,1458,2923,843,1568,2262,933,57,202,265,381,414)

DECLARE @DATE_12 DATE = DATEADD(MONTH, -12, GETDATE())
DECLARE @DATE_48 DATE = DATEADD(MONTH, -48, GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	#FB F
JOIN	WH_Virgin.trans.consumertransaction CT ON F.CINID = #FB.[CT].CINID
JOIN	#CC C 
	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate >= @DATE_12
GROUP BY F.CINID


IF OBJECT_ID('tempdb..#CC_boots') IS NOT NULL DROP TABLE #CC_boots
SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
INTO #CC_boots
FROM	WH_Virgin.trans.ConsumerCombination CC
WHERE	[WH_Virgin].[trans].[ConsumerCombination].[BrandID] IN (61)


IF OBJECT_ID('tempdb..#Trans_shoppers') IS NOT NULL DROP TABLE #Trans_shoppers
SELECT	F.CINID
INTO #Trans_shoppers
FROM	#FB F
JOIN	WH_Virgin.trans.consumertransaction CT ON F.CINID = #FB.[CT].CINID
JOIN	#CC_boots C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		Amount <> 9.35
AND		TranDate >= @DATE_12
GROUP BY F.CINID


IF OBJECT_ID('tempdb..#Trans_long_lapsed') IS NOT NULL DROP TABLE #Trans_long_lapsed
SELECT	F.CINID
INTO #Trans_long_lapsed
FROM	#FB F
JOIN	WH_Virgin.trans.consumertransaction CT ON F.CINID = #FB.[CT].CINID
JOIN	#CC_boots C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		Amount <> 9.35
AND		TranDate between @DATE_48 and  @DATE_12
GROUP BY F.CINID



IF OBJECT_ID('Sandbox.RukanK.Boots_CompSteal_LongLapsed_21092021_virgin') IS NOT NULL DROP TABLE Sandbox.RukanK.Boots_CompSteal_LongLapsed_21092021_virgin
SELECT #FB.[CINID]
INTO	Sandbox.RukanK.Boots_CompSteal_LongLapsed_21092021_virgin
FROM #FB 
WHERE #FB.[CINID] IN (SELECT #Trans_long_lapsed.[CINID] FROM #Trans_long_lapsed)
AND #FB.[CINID] IN (SELECT #Trans.[CINID] FROM #Trans)
AND #FB.[CINID] NOT IN (SELECT #Trans_shoppers.[CINID] FROM #Trans_shoppers)

IF OBJECT_ID('[WH_Virgin].[Selections].[BTS021_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[BTS021_PreSelection]   
SELECT fb.FanID
INTO [WH_Virgin].[Selections].[BTS021_PreSelection]   
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.Boots_CompSteal_LongLapsed_21092021_virgin st
				WHERE fb.CINID = #FB.[st].CINID)

END
