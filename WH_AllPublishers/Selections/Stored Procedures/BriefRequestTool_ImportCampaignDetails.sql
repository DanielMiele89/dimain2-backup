/******************************************************************************
Author: Rory Francis
Created: 28/06/2021
Purpose: 
	- Take new CustomerIDs that have had transactions loaded into PANLess Trans & assign them a FanID
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Selections].[BriefRequestTool_ImportCampaignDetails]
--WITH EXECUTE AS 'Rory'
AS
	BEGIN
		
			MERGE [Selections].[BriefRequestTool_CampaignSetup] target			-- Destination table
			USING [Selections].[BriefRequestTool_CampaignSetup_Import] source	-- Source table
			ON target.RetailerName = source.RetailerName						-- Match criteria
			AND target.CampaignName = source.CampaignName						-- Match criteria
			AND target.CampaignCode = source.CampaignCode						-- Match criteria
			AND target.Publisher = source.Publisher								-- Match criteria
			AND target.OfferSegment = source.OfferSegment						-- Match criteria

			WHEN MATCHED
			THEN UPDATE SET	target.RetailerName							= source.RetailerName
						,	target.CampaignCode							= source.CampaignCode
						,	target.AcquireDefinition					= source.AcquireDefinition
						,	target.LapsedDefinition						= source.LapsedDefinition
						,	target.ShopperDefinition					= source.ShopperDefinition
						,	target.CampaignName							= source.CampaignName
						,	target.CampaignRewardType					= source.CampaignRewardType
						,	target.CampaignUsesPerCustomer				= source.CampaignUsesPerCustomer
						,	target.CampaignChannel						= source.CampaignChannel
						,	target.CampaignOverride						= source.CampaignOverride
						,	target.CampaignStartDate					= source.CampaignStartDate
						,	target.CampaignEndDate						= source.CampaignEndDate
						,	target.CampaignCycles						= source.CampaignCycles
						,	target.BespokeCampaign						= source.BespokeCampaign
						,	target.BespokeCampaign_Analyst				= source.BespokeCampaign_Analyst
						,	target.BespokeCampaign_PreviousCampaign		= source.BespokeCampaign_PreviousCampaign
						,	target.PreviousCampaignToCopyTargetingFrom	= source.PreviousCampaignToCopyTargetingFrom
						,	target.ReplaceExistingOffers				= source.ReplaceExistingOffers
						,	target.TakePriorityOverExistingOffers		= source.TakePriorityOverExistingOffers
						,	target.AdditionalInformation				= source.AdditionalInformation
						,	target.BespokeCampaign_BespokeCode			= source.BespokeCampaign_BespokeCode
						,	target.Publisher							= source.Publisher
						,	target.OfferSegment							= source.OfferSegment
						,	target.IronOfferID							= source.IronOfferID
						,	target.IronOfferID_AlternateRecord			= source.IronOfferID_AlternateRecord
						,	target.OfferName							= source.OfferName
						,	target.OfferStartDate						= source.OfferStartDate
						,	target.OfferEndDate							= source.OfferEndDate
						,	target.OfferBaseMarketingRate				= source.OfferBaseMarketingRate
						,	target.OfferBaseBillingRate					= source.OfferBaseBillingRate
						,	target.OfferSpendStretch1Value				= source.OfferSpendStretch1Value
						,	target.OfferAboveSpendStretch1MarketingRate	= source.OfferAboveSpendStretch1MarketingRate
						,	target.OfferAboveSpendStretch1BillingRate	= source.OfferAboveSpendStretch1BillingRate
						,	target.OfferSpendStretch2Value				= source.OfferSpendStretch2Value
						,	target.OfferAboveSpendStretch2MarketingRate	= source.OfferAboveSpendStretch2MarketingRate
						,	target.OfferAboveSpendStretch2BillingRate	= source.OfferAboveSpendStretch2BillingRate
						,	target.OfferUsesPerCustomer					= source.OfferUsesPerCustomer
						,	target.OfferChannel							= source.OfferChannel
						,	target.OfferCashbackLimit					= source.OfferCashbackLimit
						,	target.OfferThrottlePercent					= source.OfferThrottlePercent
						,	target.OfferForecastedVolumes				= source.OfferForecastedVolumes
						,	target.OfferMinAge							= source.OfferMinAge
						,	target.OfferMaxAge							= source.OfferMaxAge
						,	target.OfferGender							= source.OfferGender
						,	target.OfferMinSocialClass					= source.OfferMinSocialClass
						,	target.OfferMaxSocialClass					= source.OfferMaxSocialClass
						,	target.ForecastID							= source.ForecastID
					
				WHEN NOT MATCHED BY TARGET								-- If not matched, add new rows
				THEN INSERT (RetailerName
						,	CampaignCode
						,	AcquireDefinition
						,	LapsedDefinition
						,	ShopperDefinition
						,	CampaignName
						,	CampaignRewardType
						,	CampaignUsesPerCustomer
						,	CampaignChannel
						,	CampaignOverride
						,	CampaignStartDate
						,	CampaignEndDate
						,	CampaignCycles
						,	BespokeCampaign
						,	BespokeCampaign_Analyst
						,	BespokeCampaign_PreviousCampaign
						,	PreviousCampaignToCopyTargetingFrom
						,	ReplaceExistingOffers
						,	TakePriorityOverExistingOffers
						,	AdditionalInformation
						,	BespokeCampaign_BespokeCode
						,	Publisher
						,	OfferSegment
						,	IronOfferID
						,	IronOfferID_AlternateRecord
						,	OfferName
						,	OfferStartDate
						,	OfferEndDate
						,	OfferBaseMarketingRate
						,	OfferBaseBillingRate
						,	OfferSpendStretch1Value
						,	OfferAboveSpendStretch1MarketingRate
						,	OfferAboveSpendStretch1BillingRate
						,	OfferSpendStretch2Value
						,	OfferAboveSpendStretch2MarketingRate
						,	OfferAboveSpendStretch2BillingRate
						,	OfferUsesPerCustomer
						,	OfferChannel
						,	OfferCashbackLimit
						,	OfferThrottlePercent
						,	OfferForecastedVolumes
						,	OfferMinAge
						,	OfferMaxAge
						,	OfferGender
						,	OfferMinSocialClass
						,	OfferMaxSocialClass
						,	ForecastID)
					VALUES (source.RetailerName
						,	source.CampaignCode
						,	source.AcquireDefinition
						,	source.LapsedDefinition
						,	source.ShopperDefinition
						,	source.CampaignName
						,	source.CampaignRewardType
						,	source.CampaignUsesPerCustomer
						,	source.CampaignChannel
						,	source.CampaignOverride
						,	source.CampaignStartDate
						,	source.CampaignEndDate
						,	source.CampaignCycles
						,	source.BespokeCampaign
						,	source.BespokeCampaign_Analyst
						,	source.BespokeCampaign_PreviousCampaign
						,	source.PreviousCampaignToCopyTargetingFrom
						,	source.ReplaceExistingOffers
						,	source.TakePriorityOverExistingOffers
						,	source.AdditionalInformation
						,	source.BespokeCampaign_BespokeCode
						,	source.Publisher
						,	source.OfferSegment
						,	source.IronOfferID
						,	source.IronOfferID_AlternateRecord
						,	source.OfferName
						,	source.OfferStartDate
						,	source.OfferEndDate
						,	source.OfferBaseMarketingRate
						,	source.OfferBaseBillingRate
						,	source.OfferSpendStretch1Value
						,	source.OfferAboveSpendStretch1MarketingRate
						,	source.OfferAboveSpendStretch1BillingRate
						,	source.OfferSpendStretch2Value
						,	source.OfferAboveSpendStretch2MarketingRate
						,	source.OfferAboveSpendStretch2BillingRate
						,	source.OfferUsesPerCustomer
						,	source.OfferChannel
						,	source.OfferCashbackLimit
						,	source.OfferThrottlePercent
						,	source.OfferForecastedVolumes
						,	source.OfferMinAge
						,	source.OfferMaxAge
						,	source.OfferGender
						,	source.OfferMinSocialClass
						,	source.OfferMaxSocialClass
						,	source.ForecastID
						);

				--When there is a row that exists in target and same record does not exist in source then delete this record target
				DELETE cs
				FROM [Selections].[BriefRequestTool_CampaignSetup] cs
				WHERE NOT EXISTS (	SELECT 1
									FROM [Selections].[BriefRequestTool_CampaignSetup_Import] csi
									WHERE cs.RetailerName = csi.RetailerName
									AND cs.CampaignCode = csi.CampaignCode
									AND cs.CampaignName = csi.CampaignName									
									AND cs.Publisher = csi.Publisher
									AND cs.OfferSegment = csi.OfferSegment)
				AND EXISTS (		SELECT 1
									FROM [Selections].[BriefRequestTool_CampaignSetup_Import] csi
									WHERE cs.RetailerName = csi.RetailerName
									AND cs.CampaignName = csi.CampaignName
									AND cs.CampaignCode = csi.CampaignCode)


	END

GO
GRANT EXECUTE
    ON OBJECT::[Selections].[BriefRequestTool_ImportCampaignDetails] TO [ExcelQuery_DataOps]
    AS [dbo];

