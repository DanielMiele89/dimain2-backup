/******************************************************************************
Author: Jason Shipp
Created: 31/03/2020
Purpose: 
	- Creates AMEX offer aggregation links
	- If no suitable non-AMEX offers are available for linking (there are no non-AMEX offers with similar attributes), links AMEX offers to themselves and loads the new offer attributes
	- Includes execute of the Transform.OfferReport_Insert_OfferLinks stored procedure, to update the [Report].[OfferAttributes] table and refresh the [Report].[OfferLinks] table

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Insert_OfferLinks_WithAmex]
	
AS
BEGIN
	
	SET NOCOUNT ON;


	-- Load all possible offer attribute groups that can be linked to AMEX offers

	DECLARE @StartDate date = [Report].[OfferReport_GetCycleDate](1); -- Loads dates of cycle currently being worked on
	DECLARE @EndDate date = [Report].[OfferReport_GetCycleDate](0);

	IF OBJECT_ID('tempdb..#OfferReportingPeriods_NonCardScheme') IS NOT NULL DROP TABLE #OfferReportingPeriods_NonCardScheme;
	SELECT	orp_l.PublisherID
		,	orp_l.PartnerID
		,	orp_l.StartDate
		,	orp_l.EndDate
		,	orp_l.OfferID
		,	orp_l.IronOfferID
		,	o.OfferName
		,	o.SegmentName
		,	orp_l.SegmentID

		,	orp_l.CashbackRate
		,	orp_l.SpendStretch
		,	orp_l.SpendStretchRate

		,	ol.OfferAttributeID
	INTO #OfferReportingPeriods_NonCardScheme
	FROM [Report].[OfferReport_OfferReportingPeriods] orp_l
	INNER JOIN [Derived].[Offer] o
		ON orp_l.OfferID = o.OfferID
	INNER JOIN [Derived].[Publisher] p_l
		ON orp_l.PublisherID = p_l.PublisherID
	INNER JOIN [Report].[OfferAttributes] oa
		ON oa.StartDate = orp_l.StartDate
		AND oa.EndDate = orp_l.EndDate
	INNER JOIN [Report].[OfferLinks] ol
		ON ol.OfferID = orp_l.OfferID
		AND (ol.OfferAttributeID = oa.ID OR oa.ID IS NULL)
	WHERE p_l.PublisherType != 'Card Scheme'
	AND orp_l.StartDate >= @StartDate

	IF OBJECT_ID('tempdb..#AllLinks') IS NOT NULL DROP TABLE #AllLinks;

	SELECT	DISTINCT
			OfferCode = o.OfferCode
		,	RetailerName = pa.RetailerName
		,	StartDate = orp.StartDate
		,	EndDate = orp.EndDate
		,	SpendStretch_CardScheme = ISNULL(orp.SpendStretch, 0)
		,	CashbackRate_CardScheme = COALESCE(orp.SpendStretchRate, orp.CashbackRate)
		,	LinkedOfferAttributeID = orp_l.OfferAttributeID
		,	SpendStretch = ISNULL(orp_l.SpendStretch, 0)
		,	CashbackRate = COALESCE(orp_l.SpendStretchRate, orp_l.CashbackRate)
		,	SegmentName = orp_l.SegmentName
		,	LinkedOfferName = COALESCE(orp_l.SegmentName, orp_l.OfferName)
		,	IncludesRBS = MAX(CASE WHEN orp_l.PublisherID = 132 THEN 1 ELSE 0 END) OVER (PARTITION BY o.OfferCode)
	INTO #AllLinks
	FROM [Report].[OfferReport_OfferReportingPeriods] orp
	INNER JOIN [Derived].[Offer] o
		ON orp.OfferID = o.OfferID
	INNER JOIN [Derived].[Publisher] p
		ON orp.PublisherID = p.PublisherID
	INNER JOIN [Derived].[Partner] pa
		ON orp.RetailerID = pa.RetailerID
	INNER JOIN #OfferReportingPeriods_NonCardScheme orp_l
		ON orp.StartDate = orp_l.StartDate
		AND orp.EndDate = orp_l.EndDate
		AND orp.PartnerID = orp_l.PartnerID
		AND (orp.SegmentID = orp_l.SegmentID OR COALESCE(orp.SegmentID, orp_l.SegmentID) IS NULL)
	WHERE p.PublisherType = 'Card Scheme'
	AND orp.StartDate >= @StartDate
	AND NOT EXISTS (SELECT 1
					FROM [Report].[OfferReport_OfferReportingPeriods] orpx
					INNER JOIN [Report].[OfferAttributes] oax
						ON orpx.StartDate = oax.StartDate
						AND orpx.EndDate = oax.EndDate
					INNER JOIN [Report].[OfferLinks] olx	
						ON orpx.OfferID = olx.OfferID
						AND oax.ID = olx.OfferAttributeID
					WHERE orp.OfferID = olx.OfferID
					AND orp.StartDate = oax.StartDate
					AND orp.EndDate = oax.EndDate);

	-- Delete links between AMEX base offers and Non-AMEX non-base offers

	DELETE
	FROM #AllLinks
	WHERE SegmentName IS NULL -- AMEX base offers
	AND NOT (LinkedOfferName LIKE '%Core%'	 -- Don't link to Non-AMEX non-base offers (so delete before continuing)
		OR LinkedOfferName LIKE '%Base%'
		OR LinkedOfferName LIKE '%Universal%'
		OR LinkedOfferName LIKE '%AllSegments%'
		OR LinkedOfferName LIKE '%Welcome');

	-- Create table for storing final offer links

	IF OBJECT_ID('tempdb..#FinalLinks') IS NOT NULL DROP TABLE #FinalLinks;

	CREATE TABLE #FinalLinks (OfferCode varchar(10), LinkedOfferAttributeID int);

	-- Load final links, based on priority logic if several links are possible for an AMEX offer

	-- Priority 1: Where spend stretches match, take the match with the minimum difference in cashback rate

	WITH Ranked AS (
		SELECT
		al.*
		, DENSE_RANK() OVER (PARTITION BY al.OfferCode ORDER BY ABS(al.CashbackRate_CardScheme - al.CashbackRate) ASC) AS CashbackRateDiffRank
		FROM #AllLinks al
		WHERE 
		al.SpendStretch_CardScheme = al.SpendStretch
	) 
	INSERT INTO #FinalLinks (OfferCode, LinkedOfferAttributeID)
	SELECT 
	r.OfferCode
	, MAX(r.LinkedOfferAttributeID) AS LinkedOfferAttributeID -- Use max to avoid duplication
	FROM Ranked r
	WHERE
	r.CashbackRateDiffRank = 1
	GROUP BY 
	r.OfferCode;

	-- Priority 2: Where spend stretches don't match, take the match with minimum difference in spend stretch and cashback rate (these conditions must overlap)

	INSERT INTO #FinalLinks (OfferCode, LinkedOfferAttributeID)
	SELECT 
	x.OfferCode
	, MAX(x.LinkedOfferAttributeID) AS LinkedOfferAttributeID -- Use max to avoid duplication
	FROM (
		SELECT
		al.*
		, DENSE_RANK() OVER (PARTITION BY al.OfferCode ORDER BY ABS(al.SpendStretch_CardScheme - al.SpendStretch) ASC) AS SpendStretchDiffRank
		, DENSE_RANK() OVER (PARTITION BY al.OfferCode ORDER BY ABS(al.CashbackRate_CardScheme - al.CashbackRate) ASC ) AS CashbackRateDiffRank
		FROM #AllLinks al
		WHERE 
		NOT EXISTS (SELECT NULL FROM #FinalLinks f WHERE al.OfferCode = f.OfferCode)
	) x
	WHERE
	x.SpendStretchDiffRank = 1
	AND x.CashbackRateDiffRank = 1
	GROUP BY
	x.OfferCode;

	-- Priority 3: For any offers left, take the match associated with nFIs-only

	INSERT INTO #FinalLinks (OfferCode, LinkedOfferAttributeID)
	SELECT 
	al.OfferCode
	, MAX(al.LinkedOfferAttributeID) AS LinkedOfferAttributeID -- Use max to avoid duplication
	FROM #AllLinks al
	WHERE
	al.IncludesRBS = 0
	AND NOT EXISTS (SELECT NULL FROM #FinalLinks f WHERE al.OfferCode = f.OfferCode)
	GROUP BY 
	al.OfferCode;

	-- Priority 4: For any offers left, take the match associated with either the minimum difference in spend stretch or cashback rate
	-- This is a bit random, but this shouldn't really matter if there are still AMEX offers left at this stage

	INSERT INTO #FinalLinks (OfferCode, LinkedOfferAttributeID)
	SELECT
	x.OfferCode
	, MAX(x.LinkedOfferAttributeID) AS LinkedOfferAttributeID -- Use max to avoid duplication
	FROM (
		SELECT
		al.*
		, DENSE_RANK() OVER (PARTITION BY al.OfferCode ORDER BY ABS(al.SpendStretch_CardScheme - al.SpendStretch) ASC) AS SpendStretchDiffRank
		, DENSE_RANK() OVER (PARTITION BY al.OfferCode ORDER BY ABS(al.CashbackRate_CardScheme - al.CashbackRate) ASC ) AS CashbackRateDiffRank
		FROM #AllLinks al
		WHERE 
		NOT EXISTS (SELECT NULL FROM #FinalLinks f WHERE al.OfferCode = f.OfferCode)
	) x
	WHERE (
	x.SpendStretchDiffRank = 1
	OR x.CashbackRateDiffRank = 1
	)
	GROUP BY
	x.OfferCode;

	-- Insert new AMEX Offer links

	INSERT INTO [Report].[AmexOfferLinks] (OfferCode_PreviouslyAmexOfferID, LinkedOfferID)
	SELECT	DISTINCT
			OfferCode
		,	LinkedOfferAttributeID
	FROM #FinalLinks fl
	WHERE NOT EXISTS (	SELECT 1
						FROM [Report].[AmexOfferLinks] aol
						WHERE fl.OfferCode = aol.OfferCode_PreviouslyAmexOfferID
						AND fl.LinkedOfferAttributeID = aol.LinkedOfferID);
	
	-- Update OfferAttributes and refresh OfferLinks tables

	EXEC [Report].[OfferReport_Insert_OfferLinks];

	-- Fetch cycles set up in [Report].[IronOffer_References] table

	IF OBJECT_ID('tempdb..#OfferReportingPeriods') IS NOT NULL DROP TABLE #OfferReportingPeriods;
	SELECT	DISTINCT 
			ior.StartDate
		,	ior.EndDate
	INTO #OfferReportingPeriods
	FROM [Report].[OfferReport_OfferReportingPeriods] ior;

	CREATE CLUSTERED INDEX CIX_T1_OfferCyclesID ON #OfferReportingPeriods (StartDate, EndDate);

	-- Load AMEX Offers still missing aggregation links

	IF OBJECT_ID('tempdb..#ToSelfLink') IS NOT NULL DROP TABLE #ToSelfLink;

	SELECT	a.OfferID
		,	a.IronOfferID
		,	a.OfferCode
		,	a.StartDate
		,	a.EndDate
		,	SpendStretch = a.SpendStretchAmount_1
		,	CashbackOffer = a.BaseCashBackRate
		,	TargetAudience = a.OfferName
	INTO #ToSelfLink
	FROM [Derived].[Offer] a -- Get all AMEX offers
	WHERE NOT EXISTS (	SELECT 1
						FROM [Derived].[Offer] ao -- An AMEX offer
						INNER JOIN [Report].[AmexOfferLinks] aol -- That has been linked
							ON aol.OfferCode_PreviouslyAmexOfferID = ao.OfferCode
						INNER JOIN [Report].[OfferAttributes] oa -- With an appropriate AttributeID
							ON oa.ID = aol.LinkedOfferID
						INNER JOIN #OfferReportingPeriods orp -- For this list of potential cycles
							ON orp.StartDate = oa.StartDate
							AND orp.EndDate = oa.EndDate
						WHERE a.OfferID = ao.OfferID -- Where the Iron Offer is AMEX
						AND orp.EndDate >= @StartDate -- And the cycle occurred in the period
						AND orp.StartDate <= @EndDate 
						AND ao.EndDate >= @StartDate -- And the AMEX Offer occurred in the period
						AND ao.StartDate <= @EndDate)
	AND a.EndDate >= @StartDate  -- For AMEX offers that occured in the period
	AND a.StartDate <= @EndDate;

	-- Insert missing offer attributes for the cycle being worked on

	INSERT INTO [Report].[OfferAttributes] (StartDate
										,	EndDate
										,	ShopperSegmentTypeID
										,	OfferTypeID
										,	CashbackRate
										,	SpendStretch
										,	SpendStretchRate
										,	PartnerID)
	SELECT	ior.StartDate
		,	ior.EndDate
		,	ior.SegmentID
		,	ior.OfferTypeID
		,	ior.CashbackRate
		,	ior.SpendStretch
		,	ior.SpendStretchRate
		,	ior.PartnerID
	FROM [Report].[OfferReport_OfferReportingPeriods] ior
	WHERE EXISTS (	SELECT NULL
					FROM #ToSelfLink tsl
					WHERE ior.OfferID = tsl.OfferID)
	AND ior.StartDate <= @EndDate
	AND ior.EndDate >= @StartDate
	AND NOT EXISTS (SELECT NULL	 -- Avoid duplication
					FROM [Report].[OfferAttributes] oa
					WHERE oa.StartDate = ior.StartDate
					AND oa.EndDate = ior.EndDate
					AND (oa.ShopperSegmentTypeID = ior.SegmentID OR (oa.ShopperSegmentTypeID IS NULL AND ior.SegmentID IS NULL))
					AND oa.OfferTypeID = ior.OfferTypeID
					AND (oa.CashbackRate = ior.CashbackRate OR (oa.CashbackRate IS NULL AND ior.CashbackRate IS NULL))
					AND (oa.SpendStretch = ior.SpendStretch OR (oa.SpendStretch IS NULL AND ior.SpendStretch IS NULL))
					AND (oa.SpendStretchRate = ior.SpendStretchRate OR (oa.SpendStretchRate IS NULL AND ior.SpendStretchRate IS NULL))
					AND oa.PartnerID = ior.PartnerID);

	-- Insert missing links for the cycle being worked on

	IF OBJECT_ID('tempdb..#AmexOfferLinksStaging') IS NOT NULL DROP TABLE #AmexOfferLinksStaging;
	SELECT	DISTINCT
			ao.OfferCode
		,	oa.ID
		,	COUNT(*) OVER (PARTITION BY ao.OfferCode) AS OfferCodeCount -- Identify if multiple links have been created per AMEX offer
	INTO #AmexOfferLinksStaging
	FROM [Report].[OfferReport_OfferReportingPeriods] ior
	INNER JOIN [Report].[OfferAttributes] oa
		ON oa.StartDate = ior.StartDate
		AND oa.EndDate = ior.EndDate
		AND (oa.ShopperSegmentTypeID = ior.SegmentID OR (oa.ShopperSegmentTypeID IS NULL AND ior.SegmentID IS NULL))
		AND oa.OfferTypeID = ior.OfferTypeID
		AND (oa.CashbackRate = ior.CashbackRate OR (oa.CashbackRate IS NULL AND ior.CashbackRate IS NULL))
		AND (oa.SpendStretch = ior.SpendStretch OR (oa.SpendStretch IS NULL AND ior.SpendStretch IS NULL))
		AND (oa.SpendStretchRate = ior.SpendStretchRate OR (oa.SpendStretchRate IS NULL AND ior.SpendStretchRate IS NULL))
		AND oa.PartnerID = ior.PartnerID
	INNER JOIN [Derived].[Offer] ao
		ON ao.OfferID = ior.OfferID
	WHERE EXISTS (	SELECT NULL
					FROM #ToSelfLink tsl
					WHERE ior.OfferID = tsl.OfferID)
	AND ior.StartDate <= @EndDate
	AND ior.EndDate >= @StartDate;

	IF OBJECT_ID('tempdb..#AmexIDs') IS NOT NULL DROP TABLE #AmexIDs;

	SELECT	DISTINCT
			OfferCode
		,	ROW_NUMBER() OVER(ORDER BY OfferCode) AS RowNum
	INTO #AmexIDs
	FROM (	SELECT	DISTINCT
					OfferCode
			FROM #AmexOfferLinksStaging
			WHERE OfferCodeCount > 1) AmexIDs;

	IF OBJECT_ID('tempdb..#IDs') IS NOT NULL DROP TABLE #IDs;
	SELECT	DISTINCT
			OfferCode
		,	ID
		,	ROW_NUMBER() OVER(PARTITION BY OfferCode ORDER BY ID) AS RowNum
	INTO #IDs
	FROM (	SELECT	DISTINCT
					OfferCode
				,	ID
			FROM #AmexOfferLinksStaging
			WHERE OfferCodeCount >1) IDs;

	INSERT INTO [Report].[AmexOfferLinks] (OfferCode_PreviouslyAmexOfferID, LinkedOfferID)
	SELECT	OfferCode
		,	ID
	FROM #AmexOfferLinksStaging
	WHERE OfferCodeCount = 1
	UNION ALL
	SELECT	ai.OfferCode -- Remove multiple links per AMEX offer- keep top link only by OfferAttribute ID
		,	i.ID
	FROM #AmexIDs ai
	INNER JOIN #IDs i
		ON ai.OfferCode = i.OfferCode
		AND ai.RowNum = i.RowNum;

END