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
CREATE PROCEDURE [Staging].[OfferReport_Fetch_ConsumerCombinations_20220329] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	-- Load Retailer-brand minimum and maximum analysis dates

	;WITH
	RetailerDetails AS (SELECT	o.PartnerID
							,	oe.BrandID
							,	MIN(o.StartDate) AS MinStartDate
							,	MAX(COALESCE(o.EndDate, '9999-12-31')) AS MaxEndDate
						FROM [Staging].[OfferReport_AllOffers] o
						INNER JOIN [Staging].[OfferReport_OutlierExclusion] oe -- lazily used to get brandid for partners, partners not in this table get excluded in the transaction fetch anyway (Hayden Reid)
							ON o.PartnerID = oe.PartnerID
					--	WHERE o.PartnerID = 4866
						GROUP BY	o.PartnerID
								,	oe.BrandID),

	BooHooMan AS (	SELECT	PartnerID
						,	3335 AS BrandID
						,	MinStartDate
						,	MaxEndDate
					FROM RetailerDetails
					WHERE PartnerID = 4917),

	Retailers AS (	SELECT	PartnerID
						,	BrandID
						,	MinStartDate
						,	MaxEndDate
					FROM RetailerDetails
					UNION
					SELECT	PartnerID
						,	BrandID
						,	MinStartDate
						,	MaxEndDate
					FROM BooHooMan)
	-- Fetch ConsumerCombinationIDs for incentivised MIDs

	--	Fanatics / Kitbag
	SELECT	DISTINCT
			cc.ConsumerCombinationID
		,	d.PartnerID
		,	1 AS IsWarehouse
		,	0 AS IsVirgin
		,	0 AS IsVisaBarclaycard
	FROM Retailers d
	INNER JOIN [Warehouse].[Relational].[MIDTrackingGAS] mtg
		ON d.PartnerID = mtg.PartnerID
		AND mtg.StartDate <= d.MaxEndDate -- Ensure MIDs are active for at least one day over which each retailer is being analysed
		AND (mtg.EndDate >= d.MinStartDate OR mtg.EndDate IS NULL)
	INNER JOIN [Warehouse].[Relational].[ConsumerCombination] cc
		ON COALESCE(mtg.MID_Join, mtg.MID_GAS) = cc.MID	--	Only include incentivised MIDs
	WHERE d.PartnerID = 4825

	UNION	
	
	--	Bicester Village
	SELECT	DISTINCT
			cc.ConsumerCombinationID
		,	d.PartnerID
		,	1 AS IsWarehouse
		,	0 AS IsVirgin
		,	0 AS IsVisaBarclaycard
	FROM Retailers d
	INNER JOIN [Warehouse].[Relational].[MIDTrackingGAS] mtg
		ON d.PartnerID = mtg.PartnerID
		AND mtg.StartDate <= d.MaxEndDate -- Ensure MIDs are active for at least one day over which each retailer is being analysed
		AND (mtg.EndDate >= d.MinStartDate OR mtg.EndDate IS NULL)
	INNER JOIN [Warehouse].[Relational].[ConsumerCombination] cc
		ON COALESCE(mtg.MID_Join, mtg.MID_GAS) = cc.MID	--	Only include incentivised MIDs
	WHERE d.PartnerID = 4938

	UNION

	SELECT	DISTINCT
			cc.ConsumerCombinationID
		,	d.PartnerID
		,	1 AS IsWarehouse
		,	0 AS IsVirgin
		,	0 AS IsVisaBarclaycard
	FROM Retailers d
	INNER JOIN [Warehouse].[Relational].[ConsumerCombination] cc 
		ON d.BrandID = cc.BrandID
	INNER JOIN [Warehouse].[Relational].[MIDTrackingGAS] g
		ON cc.MID = COALESCE(g.MID_Join, g.MID_GAS) -- Only include incentivised MIDs
		AND g.StartDate <= d.MaxEndDate -- Ensure MIDs are active for at least one day over which each retailer is being analysed
		AND (g.EndDate >= d.MinStartDate OR g.EndDate IS NULL)

	UNION

	--	Fanatics / Kitbag
	SELECT	DISTINCT
			cc.ConsumerCombinationID
		,	d.PartnerID
		,	0 AS IsWarehouse
		,	1 AS IsVirgin
		,	0 AS IsVisaBarclaycard
	FROM Retailers d
	INNER JOIN [Warehouse].[Relational].[MIDTrackingGAS] mtg
		ON d.PartnerID = mtg.PartnerID
		AND mtg.StartDate <= d.MaxEndDate -- Ensure MIDs are active for at least one day over which each retailer is being analysed
		AND (mtg.EndDate >= d.MinStartDate OR mtg.EndDate IS NULL)
	INNER JOIN [WH_Virgin].[Trans].[ConsumerCombination] cc
		ON COALESCE(mtg.MID_Join, mtg.MID_GAS) = cc.MID	--	Only include incentivised MIDs
	WHERE d.PartnerID = 4825

	UNION

	SELECT	DISTINCT
			cc.ConsumerCombinationID
		,	d.PartnerID
		,	0 AS IsWarehouse
		,	1 AS IsVirgin
		,	0 AS IsVisaBarclaycard
	FROM Retailers d
	INNER JOIN [WH_Virgin].[Trans].[ConsumerCombination] cc 
		ON d.BrandID = cc.BrandID
	INNER JOIN [Warehouse].[Relational].[MIDTrackingGAS] g
		ON cc.MID = COALESCE(g.MID_Join, g.MID_GAS) -- Only include incentivised MIDs
		AND g.StartDate <= d.MaxEndDate -- Ensure MIDs are active for at least one day over which each retailer is being analysed
		AND (g.EndDate >= d.MinStartDate OR g.EndDate IS NULL)

	UNION

	--	Fanatics / Kitbag
	SELECT	DISTINCT
			cc.ConsumerCombinationID
		,	d.PartnerID
		,	0 AS IsWarehouse
		,	0 AS IsVirgin
		,	1 AS IsVisaBarclaycard
	FROM Retailers d
	INNER JOIN [Warehouse].[Relational].[MIDTrackingGAS] mtg
		ON d.PartnerID = mtg.PartnerID
		AND mtg.StartDate <= d.MaxEndDate -- Ensure MIDs are active for at least one day over which each retailer is being analysed
		AND (mtg.EndDate >= d.MinStartDate OR mtg.EndDate IS NULL)
	INNER JOIN [WH_Visa].[Trans].[ConsumerCombination] cc
		ON COALESCE(mtg.MID_Join, mtg.MID_GAS) = cc.MID	--	Only include incentivised MIDs
	WHERE d.PartnerID = 4825

	UNION

	SELECT	DISTINCT
			cc.ConsumerCombinationID
		,	d.PartnerID
		,	0 AS IsWarehouse
		,	0 AS IsVirgin
		,	1 AS IsVisaBarclaycard
	FROM Retailers d
	INNER JOIN [WH_Visa].[Trans].[ConsumerCombination] cc 
		ON d.BrandID = cc.BrandID
	INNER JOIN [Warehouse].[Relational].[MIDTrackingGAS] g
		ON cc.MID = COALESCE(g.MID_Join, g.MID_GAS) -- Only include incentivised MIDs
		AND g.StartDate <= d.MaxEndDate -- Ensure MIDs are active for at least one day over which each retailer is being analysed
		AND (g.EndDate >= d.MinStartDate OR g.EndDate IS NULL);

	/******************************************************************************
	-- Old logic
	
	SELECT DISTINCT
	   cc.ConsumerCombinationID
	   , o.PartnerID
    FROM Staging.OfferReport_AllOffers o
    INNER JOIN Staging.OfferReport_OutlierExclusion oe -- lazily used to get brandid for partners, partners not in this table get excluded in the transaction fetch anyway (Hayden Reid)
	   ON oe.PartnerID = o.PartnerID
    INNER JOIN Relational.ConsumerCombination cc 
	   ON cc.BrandID = oe.BrandID;
	******************************************************************************/
 
END