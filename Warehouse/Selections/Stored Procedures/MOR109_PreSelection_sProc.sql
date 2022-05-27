
CREATE PROCEDURE [Selections].[MOR109_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM warehouse.Staging.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO #CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (2644,2018,1567,1858,2662,2459,1569,2667,2839,2467,2179,2374,1634,1365,1458,2923,843,1568,2262,933,57,202,265,381,414)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO #Trans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
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
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC_boots C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		Amount <> 9.35
AND		TranDate >= DATEADD(MONTH,-12,GETDATE())
GROUP BY F.CINID


IF OBJECT_ID('tempdb..#Trans_long_lapsed') IS NOT NULL DROP TABLE #Trans_long_lapsed
SELECT	F.CINID
INTO #Trans_long_lapsed
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC_boots C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		Amount <> 9.35
AND		TranDate between DATEADD(MONTH,-48,GETDATE()) and  DATEADD(MONTH,-12,GETDATE())
GROUP BY F.CINID



IF OBJECT_ID('Sandbox.RukanK.Boots_CompSteal_LongLapsed_03092021') IS NOT NULL DROP TABLE Sandbox.RukanK.Boots_CompSteal_LongLapsed_03092021
SELECT CINID
INTO	Sandbox.RukanK.Boots_CompSteal_LongLapsed_03092021
FROM #FB 
WHERE CINID IN (SELECT CINID FROM #Trans_long_lapsed)
AND CINID IN (SELECT CINID FROM #Trans)
AND CINID NOT IN (SELECT CINID FROM #Trans_shoppers)

IF OBJECT_ID('[Warehouse].[Selections].[MOR109_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[MOR109_PreSelection]
SELECT	FanID
INTO [Warehouse].[Selections].[MOR109_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.Boots_CompSteal_LongLapsed_03092021 st
				WHERE fb.CINID = st.CINID)

END