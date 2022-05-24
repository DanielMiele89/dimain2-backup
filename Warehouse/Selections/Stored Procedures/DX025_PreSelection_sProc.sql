CREATE PROCEDURE [Selections].[DX025_PreSelection_sProc]
AS
BEGIN

---------------------------------------------------------------------------------------
------BARCLAYS
---------------------------------------------------------------------------------------
--IF OBJECT_ID('tempdb..#FB_bc') IS NOT NULL DROP TABLE #FB_bc
--SELECT	CINID, FanID
--INTO	#FB_bc
--FROM	WH_Visa.Derived.Customer  C
--JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
--WHERE	C.CurrentlyActive = 1
--CREATE CLUSTERED INDEX ix_CINID on #FB_bc(CINID)


--IF OBJECT_ID('tempdb..#CC_bc') IS NOT NULL DROP TABLE #CC_bc	
--SELECT ConsumerCombinationID
--INTO	#CC_bc
--FROM	WH_Visa.Trans.ConsumerCombination  CC
--WHERE	BrandID IN (1892)									

--IF OBJECT_ID('tempdb..#Trans_bc') IS NOT NULL DROP TABLE #Trans_bc		
--SELECT	F.CINID
--INTO	#Trans_bc
--FROM	WH_Visa.Trans.Consumertransaction CT
--JOIN	#FB_bc F ON F.CINID = CT.CINID
--JOIN	#CC_bc C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
--		AND Amount > 0
--GROUP BY F.CINID
--CREATE CLUSTERED INDEX ix_CINID on #Trans_bc(CINID)


--IF OBJECT_ID('Sandbox.RukanK.BC_currys_acquire') IS NOT NULL DROP TABLE Sandbox.RukanK.BC_currys_acquire
--SELECT	CINID
--INTO	Sandbox.RukanK.BC_currys_acquire
--FROM	#FB_bc
--WHERE	CINID NOT IN (SELECT CINID FROM #Trans_bc)
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
WHERE	CC.BrandID IN (1892)
CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC_rbs(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#trans_rbs') IS NOT NULL DROP TABLE #trans_rbs
SELECT  CT.CINID
INTO	#Trans_rbs
FROM	Relational.ConsumerTransaction_MyRewards ct
JOIN	#CC_rbs cc on ct.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN	#FB_rbs fb 	on ct.CINID = fb.CINID
WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
		AND amount > 0
GROUP BY ct.CINID
CREATE CLUSTERED INDEX ix_CINID on #Trans_rbs(CINID)


IF OBJECT_ID('Sandbox.RukanK.Currys_acquire') IS NOT NULL DROP TABLE Sandbox.RukanK.Currys_acquire
SELECT	CINID
INTO	Sandbox.RukanK.Currys_acquire
FROM	#FB_rbs
WHERE	CINID NOT IN (SELECT CINID FROM #Trans_rbs)

-------------------------------------------------------------------------------------
----VIRGIN
-------------------------------------------------------------------------------------
--IF OBJECT_ID('tempdb..#FB_vm') IS NOT NULL DROP TABLE #FB_vm
--SELECT	CINID, FanID
--INTO	#FB_VM
--FROM	WH_Virgin.Derived.Customer  C
--JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
--WHERE	C.CurrentlyActive = 1
--and AccountType IS NOT NULL
--CREATE CLUSTERED INDEX ix_CINID on #FB_VM(CINID)


--IF OBJECT_ID('tempdb..#CC_vm') IS NOT NULL DROP TABLE #CC_vm
--SELECT ConsumerCombinationID
--INTO	#CC_vm
--FROM	WH_Virgin.trans.ConsumerCombination  CC
--WHERE	BrandID IN (1892)						


--IF OBJECT_ID('tempdb..#Trans_vm') IS NOT NULL DROP TABLE #Trans_vm
--SELECT	F.CINID, COUNT(F.CINID) AS Txn
--INTO	#Trans_vm
--FROM	WH_Virgin.trans.consumertransaction CT
--JOIN	#FB_VM F ON F.CINID = CT.CINID
--JOIN	#CC_vm C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
--WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
--		AND Amount > 0
--GROUP BY F.CINID
--CREATE CLUSTERED INDEX ix_CINID on #Trans_vm(CINID)


--IF OBJECT_ID('Sandbox.RukanK.VM_Currys_acquire') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_Currys_acquire
--SELECT	CINID
--INTO	Sandbox.RukanK.VM_Currys_acquire
--FROM	#FB_VM
--WHERE	CINID NOT IN (SELECT CINID FROM #Trans_vm)

IF OBJECT_ID('[Warehouse].[Selections].[DX025_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[DX025_PreSelection]
SELECT	fb.FanID
INTO [Warehouse].[Selections].[DX025_PreSelection]
FROM #FB_rbs fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.Currys_acquire sb
				WHERE fb.CINID = sb.CINID)

END