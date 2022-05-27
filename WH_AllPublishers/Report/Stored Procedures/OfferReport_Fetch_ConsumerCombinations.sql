/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch ConsumerCombinations
PID: OC-006

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Gets the ConsumerCombinations for each partner that is to be reported on

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

10/07/2018 Jason Shipp
	- Added logic so only ConsumerCombinationIDs for incentivised MIDs in each retailer's analysis period are fetched

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Fetch_ConsumerCombinations] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	-- Load Retailer-brand minimum and maximum analysis dates
	TRUNCATE TABLE [Report].[OfferReport_ConsumerCombinations];
	
	IF OBJECT_ID('tempdb..#RetailerDetails') IS NOT NULL DROP TABLE #RetailerDetails;
	SELECT	RetailerID = pa.RetailerID
		,	PartnerID = o.PartnerID
		,	RetailerName = pa.RetailerName
		,	BrandID = pa.BrandID
		,	IsInPromgrammeControlGroup = o.IsInPromgrammeControlGroup
		,	DataSource =	CASE
								WHEN o.IsInPromgrammeControlGroup = 0 THEN 'Warehouse'
								WHEN o.IsInPromgrammeControlGroup = 1 AND o.PublisherID IN (132, 138) THEN 'Warehouse'
								WHEN o.IsInPromgrammeControlGroup = 1 AND o.PublisherID IN (166) THEN 'WH_Virgin'
								WHEN o.IsInPromgrammeControlGroup = 1 AND o.PublisherID IN (180) THEN 'WH_Visa'
							END
		,	MinStartDate = MIN(o.StartDate)
		,	MaxEndDate = MAX(o.EndDate)
	INTO #RetailerDetails
	FROM [Report].[OfferReport_AllOffers] o
	INNER JOIN [Derived].[Partner] pa
		ON o.PartnerID = pa.PartnerID
	GROUP BY	pa.RetailerID
			,	o.PartnerID
			,	pa.RetailerName
			,	pa.BrandID
			,	o.IsInPromgrammeControlGroup
			,	CASE
								WHEN o.IsInPromgrammeControlGroup = 0 THEN 'Warehouse'
								WHEN o.IsInPromgrammeControlGroup = 1 AND o.PublisherID IN (132, 138) THEN 'Warehouse'
								WHEN o.IsInPromgrammeControlGroup = 1 AND o.PublisherID IN (166) THEN 'WH_Virgin'
								WHEN o.IsInPromgrammeControlGroup = 1 AND o.PublisherID IN (180) THEN 'WH_Visa'
							END
	
	INSERT INTO #RetailerDetails
	SELECT	RetailerID
		,	PartnerID
		,	RetailerName
		,	BrandID = 3335
		,	IsInPromgrammeControlGroup
		,	DataSource
		,	MinStartDate
		,	MaxEndDate
	FROM #RetailerDetails
	WHERE PartnerID = 4917


	-- Fetch ConsumerCombinationIDs for incentivised MIDs
	INSERT INTO [Report].[OfferReport_ConsumerCombinations] (	DataSource
															,	RetailerID
															,	PartnerID
															,	MID
															,	ConsumerCombinationID)
	SELECT	DISTINCT
			DataSource = d.DataSource
		,	RetailerID = d.RetailerID
		,	PartnerID = d.PartnerID
		,	MID = cc.MID
		,	ConsumerCombinationID = cc.ConsumerCombinationID
	FROM #RetailerDetails d
	INNER JOIN [Trans].[ConsumerCombination] cc 
		ON d.BrandID = cc.BrandID
		AND d.DataSource = cc.DataSource
	INNER JOIN [Warehouse].[Relational].[MIDTrackingGAS] mtg
		ON cc.MID = mtg.MID_Join -- Only include incentivised MIDs
		AND d.PartnerID = mtg.PartnerID
		AND mtg.StartDate <= d.MaxEndDate -- Ensure MIDs are active for at least one day over which each retailer is being analysed
		AND (mtg.EndDate >= d.MinStartDate OR mtg.EndDate IS NULL)
	UNION
	SELECT	DISTINCT
			DataSource = d.DataSource
		,	RetailerID = d.RetailerID
		,	PartnerID = d.PartnerID
		,	MID = cc.MID
		,	ConsumerCombinationID = cc.ConsumerCombinationID
	FROM #RetailerDetails d
	INNER JOIN [Trans].[ConsumerCombination] cc
		ON d.DataSource = cc.DataSource
--		AND d.BrandID = cc.BrandID
	INNER JOIN [Warehouse].[Relational].[MIDTrackingGAS] mtg
		ON mtg.MID_Join = cc.MID	--	Only include incentivised MIDs
		AND d.PartnerID = mtg.PartnerID
		AND mtg.StartDate <= d.MaxEndDate -- Ensure MIDs are active for at least one day over which each retailer is being analysed
		AND (mtg.EndDate >= d.MinStartDate OR mtg.EndDate IS NULL)
	WHERE d.PartnerID = 4938


	/******************************************************************************
	-- Old logic
	
	SELECT DISTINCT
	   cc.ConsumerCombinationID
	   , o.PartnerID
    FROM [Report].[OfferReport_AllOffers] o
    INNER JOIN [Report].[OfferReport_OutlierExclusion] oe -- lazily used to get brandid for partners, partners not in this table get excluded in the transaction fetch anyway (Hayden Reid)
	   ON oe.PartnerID = o.PartnerID
    INNER JOIN Relational.ConsumerCombination cc 
	   ON cc.BrandID = oe.BrandID;
	******************************************************************************/
 
END