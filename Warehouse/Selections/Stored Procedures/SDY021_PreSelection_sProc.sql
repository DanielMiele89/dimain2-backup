
CREATE PROCEDURE [Selections].[SDY021_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


--IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
--SELECT	CC.BrandID
--		,ConsumerCombinationID
--INTO	#CC
--FROM	Relational.ConsumerCombination CC
--WHERE	CC.BrandID = 1226 -- superdry
--CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC(ConsumerCombinationID)


--IF OBJECT_ID('tempdb..#Shopper') IS NOT NULL DROP TABLE #shopper
--SELECT DISTINCT CT.CINID
--INTO	#shopper
--FROM	Relational.ConsumerTransaction_MyRewards ct
--JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
--JOIN	#FB FB ON CT.CINID = FB.CINID
--WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
--		AND Amount > 0
--GROUP BY CT.CINID

--IF OBJECT_ID('tempdb..#Lapsed') IS NOT NULL DROP TABLE #Lapsed
--SELECT DISTINCT CT.CINID
--INTO	#Lapsed
--FROM	Relational.ConsumerTransaction_MyRewards ct
--JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
--JOIN	#FB FB ON CT.CINID = FB.CINID
--WHERE	TranDate >= DATEADD(MONTH,-24,GETDATE()) AND TranDate <= DATEADD(MONTH,-12,GETDATE())
--		AND Amount > 0
--GROUP BY CT.CINID

--IF OBJECT_ID('tempdb..#custs') IS NOT NULL DROP TABLE #custs
--SELECT DISTINCT CINID,
--NTILE(3) OVER (ORDER BY RAND()) as NTILE_3
--INTO	#custs
--FROM	#FB
--WHERE	CINID NOT IN (select cinid from #lapsed)
--AND CINID NOT IN (select cinid from #shopper)


--IF OBJECT_ID('Sandbox.samh.superdryAcq_GROUP2_04022022') IS NOT NULL DROP TABLE Sandbox.samh.superdryAcq_GROUP2_04022022
--SELECT	CINID
--INTO Sandbox.samh.superdryAcq_GROUP2_04022022
--FROM	#custs
--WHERE	NTILE_3 IN (2)  -- GROUP 2
--GROUP BY CINID

	IF OBJECT_ID('[Warehouse].[Selections].[SDY021_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[SDY021_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[SDY021_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.samh.superdryAcq_GROUP2_04022022  st
					WHERE fb.CINID = st.CINID)

END