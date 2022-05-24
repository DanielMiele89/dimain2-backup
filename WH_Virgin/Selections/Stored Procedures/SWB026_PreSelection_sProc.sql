
CREATE PROCEDURE [Selections].[SWB026_PreSelection_sProc] 
AS  
BEGIN

---------------------------------------------------------------------------------------
------RBS
---------------------------------------------------------------------------------------

--IF OBJECT_ID('tempdb..#FB_rbs') IS NOT NULL DROP TABLE #FB_rbs
--SELECT	CINID
--		,FanID
--		,AgeCurrent
--INTO #FB_rbs
--FROM	Relational.Customer C
--JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
--WHERE	C.CurrentlyActive = 1
--AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
----and AgeCurrent >= 55

--IF OBJECT_ID('tempdb..#CC_rbs') IS NOT NULL DROP TABLE #CC_rbs
--SELECT	BrandName
--		,CC.BrandID
--		,ConsumerCombinationID
--INTO #CC_rbs
--FROM	warehouse.Relational.ConsumerCombination CC
--JOIN	warehouse.Relational.Brand B ON B.BrandID = CC.BrandID
--WHERE	CC.BrandID IN (568,574,2434,2592,2777)

--DECLARE @DATE_36 DATE = DATEADD(MONTH, -36, GETDATE())

--IF OBJECT_ID('tempdb..#trans_rbs') IS NOT NULL DROP TABLE #trans_rbs
--select distinct ct.CINID
--into #trans_rbs
--from Warehouse.Relational.ConsumerTransaction_MyRewards ct
--join #CC_rbs cc
--	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
--join #FB_rbs fb
--	on ct.CINID = fb.CINID
--where trandate >= @DATE_36
--and amount > 0
--group by ct.CINID

---- shoppers - SOW
--IF OBJECT_ID('Sandbox.bastienc.sweatyBetty_RBS') IS NOT NULL DROP TABLE Sandbox.bastienc.sweatyBetty_RBS
--SELECT	CINID
--into Sandbox.bastienc.sweatyBetty_RBS
--FROM #trans_rbs

-------------------------------------------------------------------------------------
----VIRGIN
-------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#FB_vm') IS NOT NULL DROP TABLE #FB_vm
SELECT	CINID
		,FanID
INTO #FB_VM
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
--AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 

IF OBJECT_ID('tempdb..#CC_vm') IS NOT NULL DROP TABLE #CC_vm
SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
INTO #CC_vm
FROM	WH_Virgin.trans.ConsumerCombination  CC
WHERE	[WH_Virgin].[trans].[ConsumerCombination].[BrandID] IN (568,574,2434,2592,2777)						-- Competitors: Lu Lu Lemon, Gym shark and Fabletics

DECLARE @DATE_36 DATE = DATEADD(MONTH, -36, GETDATE())

IF OBJECT_ID('tempdb..#Trans_vm') IS NOT NULL DROP TABLE #Trans_vm
SELECT	F.CINID
INTO #Trans_vm
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB_VM F ON F.CINID = #FB_VM.[CT].CINID
JOIN	#CC_vm C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > @DATE_36
		AND Amount > 0
GROUP BY F.CINID

IF OBJECT_ID('Sandbox.bastienc.sweatyBetty_Virgin') IS NOT NULL DROP TABLE Sandbox.bastienc.sweatyBetty_Virgin
SELECT	#Trans_vm.[CINID]
INTO Sandbox.bastienc.sweatyBetty_Virgin
FROM  #Trans_vm


IF OBJECT_ID('[WH_Virgin].[Selections].[SWB026_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[SWB026_PreSelection]   
SELECT fb.FanID
INTO [WH_Virgin].[Selections].[SWB026_PreSelection]   
FROM #FB_VM fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.bastienc.sweatyBetty_Virgin st
				WHERE fb.CINID = #FB_VM.[st].CINID)

END
