
CREATE PROCEDURE [Selections].[PO046_PreSelection_sProc]
AS
BEGIN

-------------------------------------------------------------------------------------
----VIRGIN
-------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FB_vm') IS NOT NULL DROP TABLE #FB_vm
SELECT	CINID
INTO	#FB_VM
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
CREATE CLUSTERED INDEX ix_CINID on #FB_VM(CINID)

IF OBJECT_ID('tempdb..#FB_vm_age') IS NOT NULL DROP TABLE #FB_vm_age
SELECT	CINID, FanID
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


IF OBJECT_ID('Sandbox.RukanK.VM_PO_Ferries_AgeTarget_17122021') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_PO_Ferries_AgeTarget_17122021
SELECT	#FB_VM_age.[CINID]
INTO	Sandbox.RukanK.VM_PO_Ferries_AgeTarget_17122021
FROM	#FB_VM_age
WHERE	#FB_VM_age.[CINID] NOT IN (SELECT #Trans_vm.[CINID] FROM #Trans_vm)

	IF OBJECT_ID('[WH_Virgin].[Selections].[PO046_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[PO046_PreSelection]
	SELECT	fb.FanID
	INTO [WH_Virgin].[Selections].[PO046_PreSelection]
	FROM #FB_vm_age fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.VM_PO_Ferries_AgeTarget_17122021 st
					WHERE fb.CINID = #FB_vm_age.[st].CINID)

END

