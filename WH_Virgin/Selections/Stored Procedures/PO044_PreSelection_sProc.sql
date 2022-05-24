
CREATE PROCEDURE [Selections].[PO044_PreSelection_sProc]
AS
BEGIN

-------------------------------------------------------------------------------------
----VIRGIN
-------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FB_vm') IS NOT NULL DROP TABLE #FB_vm
SELECT	CINID, FanID
INTO	#FB_VM
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
CREATE CLUSTERED INDEX ix_CINID on #FB_VM(CINID)


IF OBJECT_ID('tempdb..#CC_vm') IS NOT NULL DROP TABLE #CC_vm
SELECT ConsumerCombinationID
INTO	#CC_vm
FROM	WH_Virgin.trans.ConsumerCombination  CC
WHERE	BrandID IN (235,295,269,1202)						


IF OBJECT_ID('tempdb..#Trans_vm') IS NOT NULL DROP TABLE #Trans_vm
SELECT	F.CINID, COUNT(F.CINID) AS Txn
INTO	#Trans_vm
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB_VM F ON F.CINID = CT.CINID
JOIN	#CC_vm C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
		AND Amount > 0
GROUP BY F.CINID
CREATE CLUSTERED INDEX ix_CINID on #Trans_vm(CINID)


IF OBJECT_ID('Sandbox.RukanK.VM_PO_Ferries_YoungFamily_17122021') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_PO_Ferries_YoungFamily_17122021
SELECT	CINID
INTO	Sandbox.RukanK.VM_PO_Ferries_YoungFamily_17122021
FROM	#Trans_vm
WHERE	Txn >= 3

	IF OBJECT_ID('[WH_Virgin].[Selections].[PO044_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[PO044_PreSelection]
	SELECT	fb.FanID
	INTO [WH_Virgin].[Selections].[PO044_PreSelection]
	FROM #FB_VM fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.VM_PO_Ferries_YoungFamily_17122021 st
					WHERE fb.CINID = st.CINID)

END

