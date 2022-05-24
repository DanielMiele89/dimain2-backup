
CREATE PROCEDURE [Selections].[SP023_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM warehouse.Staging.Customer_DuplicateSourceUID) 
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO	#CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (1458)									-- Space NK


IF OBJECT_ID('tempdb..#Trans_shoppers') IS NOT NULL DROP TABLE #Trans_shoppers
SELECT	F.CINID
INTO	#Trans_shoppers
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate >= DATEADD(MONTH,-9,GETDATE())
GROUP BY F.CINID
CREATE CLUSTERED INDEX ix_CINID on #Trans_shoppers(CINID)


IF OBJECT_ID('tempdb..#Trans_lapsed') IS NOT NULL DROP TABLE #Trans_lapsed
SELECT	F.CINID
INTO	#Trans_lapsed
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate BETWEEN DATEADD(MONTH,-24,GETDATE()) AND  DATEADD(MONTH,-9,GETDATE())
GROUP BY F.CINID
CREATE CLUSTERED INDEX ix_CINID on #Trans_lapsed(CINID)


IF OBJECT_ID('Sandbox.RukanK.SpaceNK_Lapsed_Customers') IS NOT NULL DROP TABLE Sandbox.RukanK.SpaceNK_Lapsed_Customers
SELECT CINID
INTO	Sandbox.RukanK.SpaceNK_Lapsed_Customers
FROM	#Trans_lapsed 
WHERE	CINID NOT IN (SELECT CINID FROM #Trans_shoppers)


	IF OBJECT_ID('[Warehouse].[Selections].[SP023_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[SP023_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[SP023_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.SpaceNK_Lapsed_Customers  st
					WHERE fb.CINID = st.CINID)

END