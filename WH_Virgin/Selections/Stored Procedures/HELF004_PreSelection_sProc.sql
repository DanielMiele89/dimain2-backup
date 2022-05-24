-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-05-30>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.HELF004_PreSelection_sProcASBEGIN
--	Fetch customers that have earnt on the acquire offer to include in the nursery offer

	IF OBJECT_ID('tempdb..#PartnerTrans_Acquire') IS NOT NULL DROP TABLE #PartnerTrans_Acquire
	SELECT	[Warehouse].[Relational].[PartnerTrans].[FanID]
	INTO #PartnerTrans_Acquire
	FROM [Warehouse].[Relational].[PartnerTrans] pt
	WHERE [Warehouse].[Relational].[PartnerTrans].[PartnerID] = 4863
	AND EXISTS (SELECT 1
				FROM [SLC_REPL].[dbo].[IronOffer] iof
				WHERE iof.PartnerID = 4863
				AND iof.Name LIKE '%acquire%'
				AND pt.IronOfferID = iof.ID)

	INSERT INTO #PartnerTrans_Acquire
	SELECT	[WH_Virgin].[Derived].[PartnerTrans].[FanID]
	FROM [WH_Virgin].[Derived].[PartnerTrans] pt
	WHERE [WH_Virgin].[Derived].[PartnerTrans].[PartnerID] = 4863
	AND EXISTS (SELECT 1
				FROM [SLC_REPL].[dbo].[IronOffer] iof
				WHERE iof.PartnerID = 4863
				AND iof.Name LIKE '%acquire%'
				AND pt.IronOfferID = iof.ID)
				
--	Fetch customers that have earnt on the shopper / nursery offer at least twice already to exclude from the nursery offer

	IF OBJECT_ID('tempdb..#PartnerTrans_Shopper') IS NOT NULL DROP TABLE #PartnerTrans_Shopper
	SELECT	[Warehouse].[Relational].[PartnerTrans].[FanID]
		,	COUNT(*) AS Transactions
	INTO #PartnerTrans_Shopper
	FROM [Warehouse].[Relational].[PartnerTrans] pt
	WHERE [Warehouse].[Relational].[PartnerTrans].[PartnerID] = 4863
	AND EXISTS (SELECT 1
				FROM [SLC_REPL].[dbo].[IronOffer] iof
				WHERE iof.PartnerID = 4863
				AND (iof.Name LIKE '%shopper%' OR iof.Name LIKE '%nursery%')
				AND pt.IronOfferID = iof.ID)
	GROUP BY [Warehouse].[Relational].[PartnerTrans].[FanID]
	HAVING COUNT(*) > 2

	INSERT INTO #PartnerTrans_Shopper
	SELECT	[WH_Virgin].[Derived].[PartnerTrans].[FanID]
		,	COUNT(*) AS Transactions
	FROM [WH_Virgin].[Derived].[PartnerTrans] pt
	WHERE [WH_Virgin].[Derived].[PartnerTrans].[PartnerID] = 4863
	AND EXISTS (SELECT 1
				FROM [SLC_REPL].[dbo].[IronOffer] iof
				WHERE iof.PartnerID = 4863
				AND (iof.Name LIKE '%shopper%' OR iof.Name LIKE '%nursery%')
				AND pt.IronOfferID = iof.ID)
	GROUP BY [WH_Virgin].[Derived].[PartnerTrans].[FanID]
	HAVING COUNT(*) > 2

--	Fetch acquire customers

	IF OBJECT_ID('tempdb..#CustomerSegment_Acquire') IS NOT NULL DROP TABLE #CustomerSegment_Acquire
	SELECT	[Warehouse].[Segmentation].[Roc_Shopper_Segment_Members].[FanID]
	INTO #CustomerSegment_Acquire
	FROM [Warehouse].[Segmentation].[Roc_Shopper_Segment_Members] sg
	WHERE sg.EndDate IS NULL
	AND sg.PartnerID = 4863
	AND sg.ShopperSegmentTypeID = 7

	INSERT INTO #CustomerSegment_Acquire
	SELECT	[WH_Virgin].[Segmentation].[Roc_Shopper_Segment_Members].[FanID]
	FROM [WH_Virgin].[Segmentation].[Roc_Shopper_Segment_Members] sg
	WHERE sg.EndDate IS NULL
	AND sg.PartnerID = 4863
	AND sg.ShopperSegmentTypeID = 7

--	Combine both customer groups

	IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
	SELECT *
	INTO #SegmentAssignment
	FROM (	SELECT #CustomerSegment_Acquire.[FanID]
			FROM #CustomerSegment_Acquire
			UNION ALL
			SELECT [pta].[FanID]
			FROM #PartnerTrans_Acquire pta
			WHERE NOT EXISTS (	SELECT 1
								FROM #PartnerTrans_Shopper pts
								WHERE #PartnerTrans_Shopper.[pta].FanID = pts.FanID)) c
If Object_ID('WH_Virgin.Selections.HELF004_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.HELF004_PreSelectionSelect #SEGMENTASSIGNMENT.[FanID]Into WH_Virgin.Selections.HELF004_PreSelectionFROM  #SEGMENTASSIGNMENTEND