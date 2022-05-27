CREATE PROCEDURE [Selections].[BriefRequestTool_OffersToSetUp] (@StartDate DATE)
AS
BEGIN

	--	DECLARE @StartDate DATE = '2021-08-26'

IF OBJECT_ID('tempdb..#BriefRequestTool_CampaignSetup') IS NOT NULL DROP TABLE #BriefRequestTool_CampaignSetup
SELECT	cs.RetailerName
	,	cs.CampaignCode
	,	cs.CampaignName
	--,	cs.CampaignStartDate
	--,	cs.CampaignEndDate
	,	CASE
			WHEN cs.BespokeCampaign = 'Yes' AND cs.BespokeCampaign_BespokeCode = '' AND cs.BespokeCampaign_Analyst != '' THEN 'Requires Bespoke Code from ' + cs.BespokeCampaign_Analyst
			WHEN cs.BespokeCampaign = 'Yes' AND cs.BespokeCampaign_BespokeCode = '' AND cs.PreviousCampaignToCopyTargetingFrom != '' THEN 'Bespoke Code to be copied from  ' + cs.PreviousCampaignToCopyTargetingFrom
			WHEN cs.BespokeCampaign = 'Yes' AND cs.BespokeCampaign_BespokeCode != '' THEN 'Bespoke Code added'
			ELSE 'No Bespoke Code required'
		END AS BespokeCodeStatus
	,	cs.ReplaceExistingOffers
	,	cs.AdditionalInformation
	,	cs.Publisher
	,	cs.OfferSegment
	,	cs.IronOfferID
	,	cs.IronOfferID_AlternateRecord
	,	cs.OfferName
	,	cs.OfferStartDate
	,	cs.OfferEndDate
	,	cs.OfferBaseMarketingRate
	,	cs.OfferBaseBillingRate
	,	cs.OfferSpendStretch1Value
	,	cs.OfferAboveSpendStretch1MarketingRate
	,	cs.OfferAboveSpendStretch1BillingRate
	,	cs.OfferSpendStretch2Value
	,	cs.OfferAboveSpendStretch2MarketingRate
	,	cs.OfferAboveSpendStretch2BillingRate
	,	cs.OfferUsesPerCustomer
	,	cs.OfferChannel
	,	cs.OfferCashbackLimit
INTO #BriefRequestTool_CampaignSetup
FROM [WH_AllPublishers].[Selections].[BriefRequestTool_CampaignSetup] cs
WHERE CONVERT(DATE, cs.CampaignStartDate, 103) = @StartDate


SELECT	cs.RetailerName
	,	cs.CampaignCode
	,	cs.CampaignName
	,	cs.Publisher
	,	cs.IronOfferID
	,	cs.IronOfferID_AlternateRecord
	,	cs.OfferName
	,	cs.OfferStartDate
	,	cs.OfferEndDate
	,	cs.OfferBaseMarketingRate
	,	cs.OfferBaseBillingRate
	,	cs.OfferSpendStretch1Value
	,	cs.OfferAboveSpendStretch1MarketingRate
	,	cs.OfferAboveSpendStretch1BillingRate
	,	cs.OfferSpendStretch2Value
	,	cs.OfferAboveSpendStretch2MarketingRate
	,	cs.OfferAboveSpendStretch2BillingRate
	,	cs.OfferUsesPerCustomer
	,	cs.OfferChannel
	,	cs.OfferCashbackLimit
FROM #BriefRequestTool_CampaignSetup cs
ORDER BY	cs.RetailerName
		,	cs.CampaignCode
		,	cs.Publisher
		,	cs.OfferSegment

END