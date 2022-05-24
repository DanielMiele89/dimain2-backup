
CREATE PROCEDURE [Selections].[STW026_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO	#FB
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
INTO	#CC
FROM	WH_Virgin.trans.ConsumerCombination  CC
WHERE	[WH_Virgin].[trans].[ConsumerCombination].[BrandID] IN (2648)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
		,COUNT(CT.CINID) Txn
INTO	#Trans
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB F ON F.CINID = #FB.[CT].CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.RukanK.VM_STWCshopper') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_STWCshopper
SELECT	#Trans.[CINID]
INTO Sandbox.RukanK.VM_STWCshopper
FROM	#Trans 
WHERE #Trans.[Txn] = 1
GROUP BY #Trans.[CINID]

IF OBJECT_ID('[WH_Virgin].[Selections].[STW026_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[STW026_PreSelection]
SELECT	[fb].[FanID]
INTO [WH_Virgin].[Selections].[STW026_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.VM_STWCshopper st
				WHERE fb.CINID = #FB.[st].CINID)UNION ALLSELECT [WH_Virgin].[Segmentation].[Roc_Shopper_Segment_Members].[FanID]FROM WH_Virgin.[Segmentation].[Roc_Shopper_Segment_Members] sgWHERE sg.EndDate IS NULLAND sg.ShopperSegmentTypeID = 8AND sg.PartnerID = 4778
END
