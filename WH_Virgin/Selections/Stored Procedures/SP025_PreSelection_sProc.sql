
CREATE PROCEDURE [Selections].[SP025_PreSelection_sProc]
AS
BEGIN

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
WHERE	BrandID IN (1458)																		-- Space NK


IF OBJECT_ID('tempdb..#Trans_vm') IS NOT NULL DROP TABLE #Trans_vm			-- 1,438
SELECT	F.CINID
INTO	#Trans_vm
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB_VM F ON F.CINID = CT.CINID
JOIN	#CC_vm C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -9, GETDATE())
		AND Amount > 0
GROUP BY F.CINID
CREATE CLUSTERED INDEX ix_CINID on #Trans_vm(CINID)


IF OBJECT_ID('tempdb..#Trans_lapsed_vm') IS NOT NULL DROP TABLE #Trans_lapsed_vm		-- 785
SELECT	F.CINID
INTO	#Trans_lapsed_vm
FROM	#FB_VM F
JOIN	WH_Virgin.trans.consumertransaction CT ON F.CINID = CT.CINID
JOIN	#CC_vm	 C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0
AND		TranDate BETWEEN DATEADD(MONTH,-24,GETDATE()) AND  DATEADD(MONTH,-9,GETDATE())
GROUP BY F.CINID
CREATE CLUSTERED INDEX ix_CINID on #Trans_lapsed_vm(CINID)



IF OBJECT_ID('Sandbox.RukanK.VM_SpaceNK_Lapsed_Customers2') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_SpaceNK_Lapsed_Customers2		--470
SELECT	CINID
INTO	Sandbox.RukanK.VM_SpaceNK_Lapsed_Customers2
FROM	#Trans_lapsed_vm
WHERE	CINID NOT IN (SELECT CINID FROM #Trans_vm)



	IF OBJECT_ID('[WH_Virgin].[Selections].[SP025_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[SP025_PreSelection]
	SELECT FanID
	INTO [WH_Virgin].[Selections].[SP025_PreSelection]
	FROM #FB_VM fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.VM_SpaceNK_Lapsed_Customers2  st
					WHERE fb.CINID = st.CINID)

END
