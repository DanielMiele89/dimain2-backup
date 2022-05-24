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
CREATE PROCEDURE [Staging].[OfferReport_Fetch_ConsumerCombinations_20210310] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	
	-- Load Retailer-brand minimum and maximum analysis dates

	WITH RetailerDetails AS (

		SELECT
			o.PartnerID
			, oe.BrandID
			, MIN(o.StartDate) AS MinStartDate
			, MAX(o.EndDate) AS MaxEndDate
		FROM Staging.OfferReport_AllOffers o
		INNER JOIN Staging.OfferReport_OutlierExclusion oe -- lazily used to get brandid for partners, partners not in this table get excluded in the transaction fetch anyway (Hayden Reid)
			ON o.PartnerID = oe.PartnerID
		GROUP BY
			o.PartnerID
			, oe.BrandID
	) 

	-- Fetch ConsumerCombinationIDs for incentivised MIDs

	SELECT DISTINCT
		cc.ConsumerCombinationID
		, d.PartnerID
	FROM RetailerDetails d
	INNER JOIN Relational.ConsumerCombination cc 
		ON d.BrandID = cc.BrandID
	INNER JOIN Warehouse.Relational.MIDTrackingGAS g 
		ON cc.MID = g.MID_Join -- Only include incentivised MIDs
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