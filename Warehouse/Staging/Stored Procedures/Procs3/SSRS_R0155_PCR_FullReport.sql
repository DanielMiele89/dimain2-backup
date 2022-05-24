/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0013.

					This pulls off the data related to new offers so they
					can be passed on for checking, the data pulled includes the
					Ad Space weightings.

	Update:			08-07-2014 SB - Updated to deal with 2% non-core entries in table
					02/02/2016 SB - Added DisplaySuppressed field to see which offers which
									not be visible to the client when they log into the website
					24/05/2017 ZT - Added checks in comparison to PartnerDeals table and extended
									to nFI's

					
*/
CREATE PROCEDURE [Staging].[SSRS_R0155_PCR_FullReport]
AS
	BEGIN

		SET NOCOUNT ON

		IF OBJECT_ID('tempdb..#IronOfferDetails') IS NOT NULL DROP TABLE #IronOfferDetails
		SELECT	iof.ID AS IronOfferID
			,	iof.Name AS IronOfferName
			,	iof.StartDate
			,	iof.EndDate
			,	pa.ID AS PartnerID
			,	pa.Name AS PartnerName
			,	cl.ID AS ClubID
			,	cl.Name AS ClubName
			,	DATEDIFF(DAY, iof.StartDate, iof.EndDate) + 1  as OfferPeriod
			,	iof.IsSignedOff
			,	iof.DisplaySuppressed
			,	iof.IsAppliedToAllMembers
			,	pcr.RequiredMerchantID
			,	pcr.RequiredMinimumBasketSize
			,	pcr.RequiredChannel
			,	MAX(CASE
						WHEN pcr.TypeID = 1 AND pcr.Status = 1 THEN pcr.CommissionRate
						ELSE NULL
					END) AS CashbackRate
			,	MAX(CASE
						WHEN pcr.TypeID = 2 AND pcr.Status = 1 THEN pcr.CommissionRate
						ELSE NULL
					END) AS CommissionRate
			,	MAX(CASE	
						WHEN ioa.AdSpaceID = 8 THEN ioa.[Weight] 
						ELSE -1
					END) AS [Hero_Retail_Banner_8]
			,	MAX(CASE	
						WHEN ioa.AdSpaceID = 15 THEN ioa.[Weight] 
						ELSE -1
					END) AS [Retail_Recommendation_Item_15]
			,	MAX(CASE	
						WHEN ioa.AdSpaceID = 23 THEN ioa.[Weight] 
						ELSE -1
					END) AS [Regular_Offer_23]
		INTO #IronOfferDetails
		FROM [SLC_REPL].[dbo].[IronOffer] iof
		INNER JOIN [SLC_REPL].[dbo].[IronOfferClub] ioc
			ON iof.ID = ioc.IronOfferID
--			AND ioc.ClubID != 138
		INNER JOIN [SLC_REPL].[dbo].[Club] cl
			ON ioc.ClubID = cl.ID
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON iof.PartnerID = pa.ID
		LEFT JOIN [SLC_REPL].[dbo].[PartnerCommissionRule] pcr
			ON iof.ID = pcr.RequiredIronOfferID
			AND pcr.DeletionDate IS NULL
		LEFT JOIN [SLC_REPL].[dbo].[IronOfferAdSpace] ioa
			ON iof.ID = ioa.IronOfferID
		WHERE NOT EXISTS (	SELECT 1
							FROM [Warehouse].[Relational].[PartnerOffers_Base] pob
							WHERE iof.ID = pob.OfferID)
		AND iof.Name NOT IN ('Above the line')
		AND iof.IsTriggerOffer = 0
		AND iof.Name NOT LIKE 'SPARE%'
		AND 750 < iof.ID
		GROUP BY	iof.ID
				,	iof.Name
				,	iof.StartDate
				,	iof.EndDate
				,	pa.ID
				,	pa.Name
				,	cl.ID
				,	cl.Name
				,	DATEDIFF(DAY, iof.StartDate, iof.EndDate) + 1
				,	iof.IsSignedOff
				,	iof.DisplaySuppressed
				,	iof.IsAppliedToAllMembers
				,	pcr.RequiredMerchantID
				,	pcr.RequiredMinimumBasketSize
				,	pcr.RequiredChannel

		IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output
		SELECT	iof.IronOfferID
			,	iof.IronOfferName
			,	iof.StartDate
			,	iof.EndDate
			,	iof.OfferPeriod
			,	iof.PartnerID
			,	iof.PartnerName
			,	iof.ClubID
			,	iof.ClubName
			,	iof.IsSignedOff
			,	iof.DisplaySuppressed
			,	iof.IsAppliedToAllMembers
			,	iof.RequiredMerchantID
			,	iof.RequiredMinimumBasketSize
			,	iof.RequiredChannel
			,	iof.CashbackRate
			,	iof.CommissionRate
			,	iof.Hero_Retail_Banner_8
			,	iof.Retail_Recommendation_Item_15
			,	iof.Regular_Offer_23
			,	CASE
					WHEN pd.FixedOverride = 1 THEN iof.CashbackRate + pd.Override
					WHEN pd.FixedOverride = 0 THEN (pd.Override * iof.CashbackRate) + iof.CashbackRate
					ELSE 0
				END AS CalculatedRate
			,	pd.Override
			,	pd.FixedOverride
		INTO #Output
		FROM #IronOfferDetails iof	
		LEFT JOIN [Warehouse].[APW].[PartnerAlternate] pa
			on iof.PartnerID = pa.PartnerID
		LEFT JOIN [Warehouse].[Relational].[nFI_Partner_Deals] pd
			ON pd.PartnerID = COALESCE(pa.AlternatePartnerID, iof.PartnerID)
			AND pd.ClubID = CASE WHEN iof.ClubID = 138 THEN 132 ELSE iof.ClubID END
			AND pd.EndDate IS NULL
			
		IF OBJECT_ID('tempdb..#MyRewardsOffers') IS NOT NULL DROP TABLE #MyRewardsOffers
		SELECT IronOfferID
		INTO #MyRewardsOffers
		FROM #Output
		WHERE ClubID IN (132, 138)
		GROUP BY IronOfferID
		HAVING COUNT(DISTINCT ClubID) > 1

		UPDATE op
		SET ClubID = 132
		,	ClubName = 'NatWest MyRewards'
		FROM #Output op
		INNER JOIN #MyRewardsOffers mro
			ON op.IronOfferID = mro.IronOfferID
	
		SELECT	DISTINCT
				IronOfferID
			,	IronOfferName
			,	StartDate
			,	EndDate
			,	OfferPeriod
			,	PartnerID
			,	REPLACE(REPLACE(PartnerName, '’', ''''), 'è', 'e') AS PartnerName
			,	ClubID
			,	ClubName
			,	IsSignedOff
			,	DisplaySuppressed
			,	IsAppliedToAllMembers
			,	RequiredMerchantID
			,	RequiredMinimumBasketSize
			,	RequiredChannel
			,	CashbackRate
			,	CommissionRate
			,	Hero_Retail_Banner_8
			,	Retail_Recommendation_Item_15
			,	Regular_Offer_23
			,	CalculatedRate
			,	Override
			,	FixedOverride
		FROM #Output
		ORDER BY	ClubName
				,	PartnerName
				,	IronOfferName
				,	IronOfferID


	END