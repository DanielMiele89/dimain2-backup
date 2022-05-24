
CREATE PROCEDURE [Selections].[PO047_PreSelection_sProc]
AS
BEGIN

-------------------------------------------------------------------------------------
----RBS
-------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FB_rbs') IS NOT NULL DROP TABLE #FB_rbs								-- 3835763
SELECT	CINID, FanID
INTO	#FB_rbs
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
CREATE CLUSTERED INDEX ix_CINID on #FB_rbs(CINID)

IF OBJECT_ID('tempdb..#FB_rbs_age') IS NOT NULL DROP TABLE #FB_rbs_age						-- 711881
SELECT	CINID
INTO	#FB_rbs_age
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
		AND	SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
		AND AgeCurrent BETWEEN 18 AND 34
CREATE CLUSTERED INDEX ix_CINID on #FB_rbs_age (CINID)


IF OBJECT_ID('tempdb..#CC_rbs') IS NOT NULL DROP TABLE #CC_rbs
SELECT	CC.BrandID, ConsumerCombinationID
INTO	#CC_rbs
FROM	Relational.ConsumerCombination CC
JOIN	Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN (235,295,269,1202)
CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC_rbs(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#trans_rbs') IS NOT NULL DROP TABLE #trans_rbs
SELECT  CT.CINID, COUNT(CT.CINID) AS Txn
INTO	#Trans_rbs
FROM	Relational.ConsumerTransaction_MyRewards ct
JOIN	#CC_rbs cc on ct.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN	#FB_rbs fb 	on ct.CINID = fb.CINID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
		AND amount > 0
GROUP BY ct.CINID
HAVING	COUNT(CT.CINID) >= 3
CREATE CLUSTERED INDEX ix_CINID on #Trans_rbs(CINID)


IF OBJECT_ID('tempdb..#CC_rbs_Pets') IS NOT NULL DROP TABLE #CC_rbs_Pets
SELECT	CC.BrandID, ConsumerCombinationID
INTO	#CC_rbs_Pets
FROM	Relational.ConsumerCombination CC
JOIN	Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	SectorID = 34													-- PETS SECTOR
CREATE CLUSTERED INDEX ix_CCID on #CC_rbs_Pets(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#trans_rbs_Pets') IS NOT NULL DROP TABLE #trans_rbs_Pets		-- 266938
SELECT  CT.CINID, COUNT(CT.CINID) AS Txn
INTO	#Trans_rbs_Pets
FROM	Relational.ConsumerTransaction_MyRewards ct
JOIN	#CC_rbs_Pets cc on ct.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN	#FB_rbs fb 	on ct.CINID = fb.CINID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
		AND amount > 0
GROUP BY ct.CINID
HAVING	COUNT(CT.CINID) >= 6
CREATE CLUSTERED INDEX ix_CINID on #Trans_rbs_Pets(CINID)


IF OBJECT_ID('Sandbox.RukanK.PO_Ferries_PetOwner_20122021') IS NOT NULL DROP TABLE Sandbox.RukanK.PO_Ferries_PetOwner_20122021		-- 210,945
SELECT	CINID
INTO	Sandbox.RukanK.PO_Ferries_PetOwner_20122021
FROM	#Trans_rbs_Pets
WHERE	CINID NOT IN (SELECT CINID FROM #Trans_rbs)
AND		CINID NOT IN (SELECT CINID FROM #FB_rbs_age)

	IF OBJECT_ID('[Warehouse].[Selections].[PO047_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[PO047_PreSelection]
	SELECT	fb.FanID
	INTO [Warehouse].[Selections].[PO047_PreSelection]
	FROM #FB_rbs fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.PO_Ferries_PetOwner_20122021 st
					WHERE fb.CINID = st.CINID)

END