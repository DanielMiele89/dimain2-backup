-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-08-11>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[LW072_PreSelection_sProc]ASBEGIN

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
WHERE	[WH_Virgin].[trans].[ConsumerCombination].[BrandID] IN (246)


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


IF OBJECT_ID('Sandbox.RukanK.VM_Laithwaite_Shopper') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_Laithwaite_Shopper
SELECT	#Trans.[CINID]
INTO Sandbox.RukanK.VM_Laithwaite_Shopper
FROM	#Trans 
WHERE #Trans.[Txn] = 1
GROUP BY #Trans.[CINID]If Object_ID('WH_Virgin.Selections.LW072_PreSelection') Is Not Null Drop Table [WH_Virgin].Selections.LW072_PreSelectionSelect [fb].[FanID]Into [WH_Virgin].Selections.LW072_PreSelectionFROM  #FB fbWHERE EXISTS (	SELECT 1				FROM Sandbox.RukanK.VM_Laithwaite_Shopper st				WHERE fb.CINID = #FB.[st].CINID)UNION ALLSELECT [WH_Virgin].[Segmentation].[Roc_Shopper_Segment_Members].[FanID]FROM WH_Virgin.[Segmentation].[Roc_Shopper_Segment_Members] sgWHERE sg.EndDate IS NULLAND sg.ShopperSegmentTypeID = 8AND sg.PartnerID = 4721END