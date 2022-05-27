-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-05-30>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.HELF004_PreSelection_sProcASBEGIN
--	Fetch customers that have earnt on the acquire offer to include in the nursery offer

	IF OBJECT_ID('tempdb..#PartnerTrans_Acquire') IS NOT NULL DROP TABLE #PartnerTrans_Acquire
	SELECT	FanID
	INTO #PartnerTrans_Acquire
	FROM [Warehouse].[Relational].[PartnerTrans] pt
	WHERE PartnerID = 4863
	AND EXISTS (SELECT 1
				FROM [SLC_REPL].[dbo].[IronOffer] iof
				WHERE iof.PartnerID = 4863
				AND iof.Name LIKE '%acquire%'
				AND pt.IronOfferID = iof.ID)

	INSERT INTO #PartnerTrans_Acquire
	SELECT	FanID
	FROM [WH_Virgin].[Derived].[PartnerTrans] pt
	WHERE PartnerID = 4863
	AND EXISTS (SELECT 1
				FROM [SLC_REPL].[dbo].[IronOffer] iof
				WHERE iof.PartnerID = 4863
				AND iof.Name LIKE '%acquire%'
				AND pt.IronOfferID = iof.ID)
				
--	Fetch customers that have earnt on the shopper / nursery offer at least twice already to exclude from the nursery offer

	IF OBJECT_ID('tempdb..#PartnerTrans_Shopper') IS NOT NULL DROP TABLE #PartnerTrans_Shopper
	SELECT	FanID
		,	COUNT(*) AS Transactions
	INTO #PartnerTrans_Shopper
	FROM [Warehouse].[Relational].[PartnerTrans] pt
	WHERE PartnerID = 4863
	AND EXISTS (SELECT 1
				FROM [SLC_REPL].[dbo].[IronOffer] iof
				WHERE iof.PartnerID = 4863
				AND (iof.Name LIKE '%shopper%' OR iof.Name LIKE '%nursery%')
				AND pt.IronOfferID = iof.ID)
	GROUP BY FanID
	HAVING COUNT(*) > 2

	INSERT INTO #PartnerTrans_Shopper
	SELECT	FanID
		,	COUNT(*) AS Transactions
	FROM [WH_Virgin].[Derived].[PartnerTrans] pt
	WHERE PartnerID = 4863
	AND EXISTS (SELECT 1
				FROM [SLC_REPL].[dbo].[IronOffer] iof
				WHERE iof.PartnerID = 4863
				AND (iof.Name LIKE '%shopper%' OR iof.Name LIKE '%nursery%')
				AND pt.IronOfferID = iof.ID)
	GROUP BY FanID
	HAVING COUNT(*) > 2

--	Fetch acquire customers

	IF OBJECT_ID('tempdb..#CustomerSegment_Acquire') IS NOT NULL DROP TABLE #CustomerSegment_Acquire
	SELECT	FanID
	INTO #CustomerSegment_Acquire
	FROM [Warehouse].[Segmentation].[Roc_Shopper_Segment_Members] sg
	WHERE sg.EndDate IS NULL
	AND sg.PartnerID = 4863
	AND sg.ShopperSegmentTypeID = 7

	INSERT INTO #CustomerSegment_Acquire
	SELECT	FanID
	FROM [WH_Virgin].[Segmentation].[Roc_Shopper_Segment_Members] sg
	WHERE sg.EndDate IS NULL
	AND sg.PartnerID = 4863
	AND sg.ShopperSegmentTypeID = 7

--	Combine both customer groups

	IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
	SELECT *
	INTO #SegmentAssignment
	FROM (	SELECT FanID
			FROM #CustomerSegment_Acquire
			UNION ALL
			SELECT FanID
			FROM #PartnerTrans_Acquire pta
			WHERE NOT EXISTS (	SELECT 1
								FROM #PartnerTrans_Shopper pts
								WHERE pta.FanID = pts.FanID)) c
If Object_ID('Warehouse.Selections.HELF004_PreSelection') Is Not Null Drop Table Warehouse.Selections.HELF004_PreSelectionSelect FanIDInto Warehouse.Selections.HELF004_PreSelectionFROM  #SEGMENTASSIGNMENTEND