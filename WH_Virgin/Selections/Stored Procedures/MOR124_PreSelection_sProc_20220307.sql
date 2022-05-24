
CREATE PROCEDURE [Selections].[MOR124_PreSelection_sProc_20220307]
AS
BEGIN

	----- VIRGIN MONEY - LOW SOW
	IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
	SELECT	CINID	,FanID
	INTO #FB
	FROM	WH_Virgin.Derived.Customer  C
	JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
	WHERE	C.CurrentlyActive = 1
	and AccountType IS NOT NULL
	AND		SourceUID NOT IN (SELECT [Derived].[Customer_DuplicateSourceUID].[SourceUID] FROM Derived.Customer_DuplicateSourceUID) 


	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
			,[WH_Virgin].[trans].[ConsumerCombination].[BrandID]
	INTO #CC
	FROM	WH_Virgin.trans.ConsumerCombination  CC
	WHERE	[WH_Virgin].[trans].[ConsumerCombination].[BrandID] IN     (292,21,379,425,2541,5,254)		


	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT	F.CINID
			,1.0 * (CAST(SUM(CASE WHEN BrandID = 292 THEN Amount ELSE 0 END )as float) / NULLIF(SUM(Amount),0)) AS SoW
			,MAX(CASE WHEN BrandID = 292 AND TranDate >= DATEADD(MONTH,-3,GETDATE()) THEN 1 ELSE 0 END) BrandShopper
			,COUNT(1) as Transactions
	INTO #Trans
	FROM	#FB F
	JOIN	WH_Virgin.trans.consumertransaction CT ON F.CINID = #FB.[CT].CINID
	JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
	WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE())
			AND Amount > 0
	GROUP BY F.CINID


	IF OBJECT_ID('Sandbox.rukank.VM_Morrisons_LoW_SoW_30112021') IS NOT NULL DROP TABLE Sandbox.rukank.VM_Morrisons_LoW_SoW_30112021
	SELECT	#Trans.[CINID]
	INTO Sandbox.rukank.VM_Morrisons_LoW_SoW_30112021
	FROM	#Trans
	WHERE #Trans.[BrandShopper] = 1
		  AND #Trans.[SoW] <= 0.30
		  AND #Trans.[Transactions] >= 15
	GROUP BY #Trans.[CINID]

	IF OBJECT_ID('[WH_Virgin].[Selections].[MOR124_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[MOR124_PreSelection]
	SELECT [fb].[FanID]
	INTO [WH_Virgin].[Selections].[MOR124_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
					WHERE fb.FanID = sg.FanID
					AND sg.EndDate IS NULL
					AND sg.ShopperSegmentTypeID IN (7, 8))
	UNION ALL
	SELECT [fb].[FanID]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.VM_Morrisons_LoW_SoW_30112021 st
					WHERE fb.CINID = #FB.[st].CINID)
	AND EXISTS (	SELECT 1
					FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
					WHERE fb.FanID = sg.FanID
					AND sg.EndDate IS NULL
					AND sg.ShopperSegmentTypeID IN (9))

END



