
CREATE PROCEDURE [Selections].[PO047_PreSelection_sProc]
AS
BEGIN

-------------------------------------------------------------------------------------
----VIRGIN
-------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#FB_vm') IS NOT NULL DROP TABLE #FB_vm		-- 214481
SELECT	CINID, FanID
INTO	#FB_VM
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
CREATE CLUSTERED INDEX ix_CINID on #FB_VM(CINID)

IF OBJECT_ID('tempdb..#FB_vm_age') IS NOT NULL DROP TABLE #FB_vm_age
SELECT	CINID
INTO	#FB_VM_age
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
		AND AccountType IS NOT NULL
		AND AgeCurrent BETWEEN 18 AND 34
CREATE CLUSTERED INDEX ix_CINID on #FB_VM_age(CINID)


IF OBJECT_ID('tempdb..#CC_vm') IS NOT NULL DROP TABLE #CC_vm
SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
INTO	#CC_vm
FROM	WH_Virgin.trans.ConsumerCombination  CC
WHERE	[WH_Virgin].[trans].[ConsumerCombination].[BrandID] IN (235,295,269,1202)						


IF OBJECT_ID('tempdb..#Trans_vm') IS NOT NULL DROP TABLE #Trans_vm
SELECT	F.CINID, COUNT(F.CINID) AS Txn
INTO	#Trans_vm
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB_VM F ON F.CINID = #FB_VM.[CT].CINID
JOIN	#CC_vm C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
		AND Amount > 0
GROUP BY F.CINID
HAVING	COUNT(F.CINID) >= 3
CREATE CLUSTERED INDEX ix_CINID on #Trans_vm(CINID)


IF OBJECT_ID('tempdb..#CC_vm_Pets') IS NOT NULL DROP TABLE #CC_vm_Pets
SELECT ConsumerCombinationID
INTO	#CC_vm_Pets
FROM	WH_Virgin.trans.ConsumerCombination  CC
JOIN	Warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	SectorID = 34													-- PETS SECTOR
CREATE CLUSTERED INDEX ix_CCID on #CC_vm_Pets(ConsumerCombinationID)

IF OBJECT_ID('tempdb..#Trans_vm_Pets') IS NOT NULL DROP TABLE #Trans_vm_Pets		-- 3959
SELECT	F.CINID, COUNT(F.CINID) AS Txn
INTO	#Trans_vm_Pets
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB_VM F ON F.CINID = #FB_VM.[CT].CINID
JOIN	#CC_vm_Pets C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
		AND Amount > 0
GROUP BY F.CINID
HAVING	COUNT(F.CINID) >= 6
CREATE CLUSTERED INDEX ix_CINID on #Trans_vm_Pets(CINID)


IF OBJECT_ID('Sandbox.RukanK.VM_PO_Ferries_PetOwner_20122021') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_PO_Ferries_PetOwner_20122021		-- 3141
SELECT	#Trans_vm_Pets.[CINID]
INTO	Sandbox.RukanK.VM_PO_Ferries_PetOwner_20122021
FROM	#Trans_vm_Pets
WHERE	#Trans_vm_Pets.[CINID] NOT IN (SELECT #Trans_vm.[CINID] FROM #Trans_vm)
AND		#Trans_vm_Pets.[CINID] NOT IN (SELECT #FB_VM_age.[CINID] FROM #FB_VM_age)

	IF OBJECT_ID('[WH_Virgin].[Selections].[PO047_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[PO047_PreSelection]
	SELECT	fb.FanID
	INTO [WH_Virgin].[Selections].[PO047_PreSelection]
	FROM #FB_VM fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.VM_PO_Ferries_PetOwner_20122021 st
					WHERE fb.CINID = #FB_VM.[st].CINID)

END

