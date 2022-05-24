
CREATE PROCEDURE [Selections].[STW034_PreSelection_sProc]
AS
BEGIN

-------------------------------------------------------------------------------------
----RBS
-------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FB_rbs') IS NOT NULL DROP TABLE #FB_rbs
SELECT	CINID, FanID
INTO	#FB_rbs
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
CREATE CLUSTERED INDEX ix_CINID on #FB_rbs(CINID)


IF OBJECT_ID('tempdb..#CC_rbs') IS NOT NULL DROP TABLE #CC_rbs
SELECT	CC.BrandID, ConsumerCombinationID
INTO	#CC_rbs
FROM	Relational.ConsumerCombination CC
JOIN	Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN (480,1048,1626,1712)
CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC_rbs(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#trans_rbs') IS NOT NULL DROP TABLE #trans_rbs
SELECT  CT.CINID, FanID
INTO	#Trans_rbs
FROM	Relational.ConsumerTransaction_MyRewards ct
JOIN	#CC_rbs cc on ct.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN	#FB_rbs fb 	on ct.CINID = fb.CINID
WHERE	TranDate >= DATEADD(MONTH,-24,GETDATE())
		AND amount > 0
GROUP BY ct.CINID, FanID
CREATE CLUSTERED INDEX ix_CINID on #Trans_rbs(CINID)


IF OBJECT_ID('Sandbox.bastienc.laithwaites_RBS') IS NOT NULL DROP TABLE Sandbox.bastienc.laithwaites_RBS
SELECT	CINID, FanID
into	Sandbox.bastienc.laithwaites_RBS
FROM	#trans_rbs


	IF OBJECT_ID('[Warehouse].[Selections].[STW034_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[STW034_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[STW034_PreSelection]
	FROM Sandbox.bastienc.laithwaites_RBS

END
