/******************************************************************************
Author: Hayden Reid
Created: 17/11/2016
Purpose: 
	Loads offer attributes to aggregate over, and creates links from Iron Offer to Offer level 
------------------------------------------------------------------------------
Modification History

Jason Shipp 08/06/2018
	- Added sperate queries for Morrisons and Travelodge to allow attributes to be collected and links made for aggregation at bespoke-segment level

Jason Shipp 19/12/2018
	- Added logic to Morrisons/Travelodge offer links logic to ensure that the window function scans over relevant rows only

******************************************************************************/

CREATE PROCEDURE [Report].[OfferReport_Insert_OfferLinks]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	-- Update OfferAttributes - Distinct offer characteristics

	IF OBJECT_ID('tempdb..#OfferAttributes') IS NOT NULL DROP TABLE #OfferAttributes;
	SELECT	DISTINCT
			orp.StartDate
		,	orp.EndDate
		,	orp.PartnerID
		,	orp.SegmentID
		,	orp.OfferTypeID
		,	orp.CashbackRate
		,	orp.SpendStretch
		,	orp.SpendStretchRate
	INTO #OfferAttributes
	FROM [Report].[OfferReport_OfferReportingPeriods] orp
	INNER JOIN [Derived].[Offer] o
		ON orp.OfferID = o.OfferID
	INNER JOIN [Derived].[Publisher] p
		ON orp.PublisherID = p.PublisherID
	WHERE p.PublisherType != 'Card Scheme'
	AND o.RetailerID NOT IN (4263, 4712) -- Morrisons, Travelodge

	UNION ALL
	
	SELECT	orp.StartDate -- Morrisons bespoke attributes to allow aggregation at bespoke-segment level
		,	orp.EndDate
		,	orp.PartnerID
		,	orp.SegmentID
		,	orp.OfferTypeID
		,	MAX(CashbackRate) AS CashbackRate
		,	MAX(SpendStretch) AS SpendStretch
		,	MAX(SpendStretchRate) AS SpendStretchRate
	FROM [Report].[OfferReport_OfferReportingPeriods] orp
	INNER JOIN [Derived].[Offer] o
		ON orp.OfferID = o.OfferID
	INNER JOIN [Derived].[Publisher] p
		ON orp.PublisherID = p.PublisherID
	WHERE p.PublisherType != 'Card Scheme'
	AND o.RetailerID IN (4263, 4712) -- Morrisons, Travelodge
	GROUP BY	orp.StartDate
			,	orp.EndDate
			,	orp.PartnerID
			,	orp.SegmentID
			,	orp.OfferTypeID
	    
	INSERT INTO [Report].[OfferAttributes]
	SELECT	oa.StartDate
		,	oa.EndDate
		,	oa.SegmentID
		,	oa.OfferTypeID
		,	oa.CashbackRate
		,	oa.SpendStretch
		,	oa.SpendStretchRate
		,	oa.PartnerID
	FROM #OfferAttributes oa
	WHERE NOT EXISTS (	SELECT 1
						FROM [Report].[OfferAttributes] oa_e
						WHERE oa_e.StartDate = oa.StartDate
						AND oa_e.EndDate = oa.EndDate
						AND (oa_e.ShopperSegmentTypeID = oa.SegmentID OR (oa_e.ShopperSegmentTypeID IS NULL AND oa.SegmentID IS NULL))
						AND oa_e.OfferTypeID = oa.OfferTypeID
						AND (oa_e.CashbackRate = oa.CashbackRate OR (oa_e.CashbackRate IS NULL and oa.CashbackRate IS NULL))
						AND (oa_e.SpendStretch = oa.SpendStretch OR (oa_e.SpendStretch IS NULL and oa.SpendStretch IS NULL))
						AND (oa_e.SpendStretchRate = oa.SpendStretchRate OR (oa_e.SpendStretchRate IS NULL and oa.SpendStretchRate IS NULL))
						AND oa_e.PartnerID = oa.PartnerID);

    -- Refresh OfferLinks - Distinct list of IronOfferIDs linked to OfferAttributes
    
	TRUNCATE TABLE [Report].[OfferLinks];

    INSERT INTO [Report].[OfferLinks]
    SELECT	DISTINCT
			oa.ID
		,	orp.OfferID
		,	orp.IronOfferID
	FROM [Report].[OfferReport_OfferReportingPeriods] orp
    INNER JOIN [Report].[OfferAttributes] oa
		ON oa.StartDate = orp.StartDate
		AND oa.EndDate = orp.EndDate
		AND (oa.ShopperSegmentTypeID = orp.SegmentID OR (oa.ShopperSegmentTypeID IS NULL AND orp.SegmentID IS NULL))
		AND oa.OfferTypeID = orp.OfferTypeID
		AND (oa.CashbackRate = orp.CashbackRate OR (oa.CashbackRate IS NULL and orp.CashbackRate IS NULL))
		AND (oa.SpendStretch = orp.SpendStretch OR (oa.SpendStretch IS NULL and orp.SpendStretch IS NULL))
		AND (oa.SpendStretchRate = orp.SpendStretchRate OR (oa.SpendStretchRate IS NULL and orp.SpendStretchRate IS NULL))
		AND oa.PartnerID = orp.PartnerID
	INNER JOIN [Derived].[Offer] o
		ON orp.OfferID = o.OfferID
	INNER JOIN [Derived].[Publisher] p
		ON orp.PublisherID = p.PublisherID
	WHERE p.PublisherType != 'Card Scheme'
	AND oa.PartnerID NOT IN (4263,4712) -- Morrisons, Travelodge
	
    INSERT INTO [Report].[OfferLinks]
	SELECT	DISTINCT -- Morrisons bespoke links to allow aggregation at bespoke-segment level
			oa.ID
		,	orp2.OfferID
		,	orp2.IronOfferID
	FROM (	SELECT	orp.PublisherID
				,	orp.OfferID
				,	orp.IronOfferID
				,	orp.StartDate
				,	orp.EndDate
				,	orp.SegmentID
				,	orp.OfferTypeID
				,	orp.PartnerID
				,	(MAX(orp.CashbackRate) OVER (PARTITION BY orp.PartnerID, orp.StartDate, orp.EndDate, orp.SegmentID, orp.OfferTypeID)) AS CashbackRate	
				,	(MAX(orp.SpendStretch) OVER (PARTITION BY orp.PartnerID, orp.StartDate, orp.EndDate, orp.SegmentID, orp.OfferTypeID)) AS SpendStretch	
				,	(MAX(orp.SpendStretchRate) OVER (PARTITION BY orp.PartnerID, orp.StartDate, orp.EndDate, orp.SegmentID, orp.OfferTypeID)) AS SpendStretchRate		 
			FROM [Report].[OfferReport_OfferReportingPeriods] orp
			INNER JOIN [Report].[OfferAttributes] oa -- INNER JOIN acts as a filter to ensure window function scans over relevant rows only
				ON oa.StartDate = orp.StartDate
				AND oa.EndDate = orp.EndDate
				AND (oa.ShopperSegmentTypeID = orp.SegmentID OR (oa.ShopperSegmentTypeID IS NULL AND orp.SegmentID IS NULL))
				AND oa.OfferTypeID = orp.OfferTypeID
				AND oa.PartnerID = orp.PartnerID
			INNER JOIN [Derived].[Offer] o
				ON orp.OfferID = o.OfferID
			INNER JOIN [Derived].[Publisher] p
				ON orp.PublisherID = p.PublisherID
			WHERE p.PublisherType != 'Card Scheme'
			AND orp.PartnerID IN (4263,4712)) orp2 -- Morrisons, Travelodge
	INNER JOIN [Report].[OfferAttributes] oa
		ON oa.StartDate = orp2.StartDate
		AND oa.EndDate = orp2.EndDate
		AND (oa.ShopperSegmentTypeID = orp2.SegmentID OR (oa.ShopperSegmentTypeID IS NULL AND orp2.SegmentID IS NULL))
		AND oa.OfferTypeID = orp2.OfferTypeID
		AND (oa.CashbackRate = orp2.CashbackRate OR (oa.CashbackRate IS NULL and orp2.CashbackRate IS NULL))
		AND (oa.SpendStretch = orp2.SpendStretch OR (oa.SpendStretch IS NULL and orp2.SpendStretch IS NULL))
		AND (oa.SpendStretchRate = orp2.SpendStretchRate OR (oa.SpendStretchRate IS NULL and orp2.SpendStretchRate IS NULL))
		AND oa.PartnerID = orp2.PartnerID
		
	
    INSERT INTO [Report].[OfferLinks]
	SELECT	ol.LinkedOfferID	-- AMEX links
		,	o.OfferID 
		,	o.IronOfferID
	FROM [Report].[AmexOfferLinks] ol
	INNER JOIN [Derived].[Offer] o
		ON ol.OfferCode_PreviouslyAmexOfferID = o.OfferCode
	INNER JOIN [Derived].[Publisher] p
		ON o.PublisherID = p.PublisherID
	WHERE p.PublisherType != 'Card Scheme';

END