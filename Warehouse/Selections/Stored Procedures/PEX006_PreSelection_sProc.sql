
CREATE PROCEDURE [Selections].[PEX006_PreSelection_sProc] 
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
WHERE	BrandID IN (336)												-- Pizza Express


IF OBJECT_ID('tempdb..#Trans_shoppers') IS NOT NULL DROP TABLE #Trans_shoppers
SELECT	F.CINID
INTO #Trans_shoppers
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate >= '2019-07-01'
GROUP BY F.CINID


DECLARE @DATE_18 DATE = DATEADD(MONTH,-18,'2019-07-01')

IF OBJECT_ID('tempdb..#Trans_lapsed') IS NOT NULL DROP TABLE #Trans_lapsed
SELECT	F.CINID
INTO	#Trans_lapsed
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate BETWEEN @DATE_18 AND '2019-06-30'
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.RukanK.PizzaExpress_Lapsed_16082021') IS NOT NULL DROP TABLE Sandbox.RukanK.PizzaExpress_Lapsed_16082021
SELECT	CINID
INTO	Sandbox.RukanK.PizzaExpress_Lapsed_16082021
FROM	#Trans_lapsed 
WHERE	CINID NOT IN (SELECT CINID FROM #Trans_shoppers)


IF OBJECT_ID('Sandbox.RukanK.PizzaExpress_Acquire_16082021') IS NOT NULL DROP TABLE Sandbox.RukanK.PizzaExpress_Acquire_16082021
SELECT CINID
INTO	Sandbox.RukanK.PizzaExpress_Acquire_16082021
FROM	#FB 
WHERE	CINID NOT IN (SELECT CINID FROM #Trans_lapsed)
AND		CINID NOT IN (SELECT CINID FROM #Trans_shoppers)


IF OBJECT_ID('[Warehouse].[Selections].[PEX006_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[PEX006_PreSelection]   
SELECT fb.FanID
INTO [Warehouse].[Selections].[PEX006_PreSelection]   
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.PizzaExpress_Lapsed_16082021 st
				WHERE fb.CINID = st.CINID)
OR EXISTS (	SELECT 1
				FROM Sandbox.RukanK.PizzaExpress_Acquire_16082021 st
				WHERE fb.CINID = st.CINID)

END