
CREATE PROCEDURE [Selections].[PO044_PreSelection_sProc]
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
CREATE CLUSTERED INDEX ix_CINID on #Trans_rbs(CINID)


IF OBJECT_ID('Sandbox.RukanK.PO_Ferries_YoungFamily_17122021') IS NOT NULL DROP TABLE Sandbox.RukanK.PO_Ferries_YoungFamily_17122021
SELECT	CINID
INTO	Sandbox.RukanK.PO_Ferries_YoungFamily_17122021
FROM	#trans_rbs
WHERE	Txn >= 3

	IF OBJECT_ID('[Warehouse].[Selections].[PO044_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[PO044_PreSelection]
	SELECT	fb.FanID
	INTO [Warehouse].[Selections].[PO044_PreSelection]
	FROM #FB_rbs fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.PO_Ferries_YoungFamily_17122021 st
					WHERE fb.CINID = st.CINID)

END