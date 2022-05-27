/******************************************************************************
Author: Rory Francis
Created: 28/06/2021
Purpose: 
	- Take new CustomerIDs that have had transactions loaded into PANLess Trans & assign them a FanID
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Selections].[BriefRequestTool_ImportCampaignDetails_Import] (	@RetailerName VARCHAR(50)
																			,	@CampaignCode VARCHAR(50)
																			,	@AcquireDefinition VARCHAR(100)
																			,	@LapsedDefinition VARCHAR(100)
																			,	@ShopperDefinition VARCHAR(100)
																			,	@CampaignName VARCHAR(100)
																			,	@CampaignRewardType VARCHAR(50)
																			,	@CampaignUsesPerCustomer VARCHAR(50)
																			,	@CampaignChannel VARCHAR(50)
																			,	@CampaignOverride VARCHAR(50)
																			,	@CampaignStartDate VARCHAR(50)
																			,	@CampaignEndDate VARCHAR(50)
																			,	@CampaignCycles VARCHAR(50)
																			,	@BespokeCampaign VARCHAR(50)
																			,	@BespokeCampaign_Analyst VARCHAR(50)
																			,	@BespokeCampaign_PreviousCampaign VARCHAR(50)
																			,	@PreviousCampaignToCopyTargetingFrom VARCHAR(50)
																			,	@ReplaceExistingOffers VARCHAR(50)
																			,	@TakePriorityOverExistingOffers VARCHAR(50)
																			,	@AdditionalInformation VARCHAR(MAX)
																			,	@BespokeCampaign_BespokeCode VARCHAR(MAX)

																			,	@Publisher VARCHAR(100)
																			,	@OfferSegment VARCHAR(50)
																			,	@IronOfferID VARCHAR(50)
																			,	@IronOfferID_AlternateRecord VARCHAR(50)
																			,	@OfferName VARCHAR(50)
																			,	@OfferStartDate VARCHAR(50)
																			,	@OfferEndDate VARCHAR(50)
																			,	@OfferBaseMarketingRate VARCHAR(50)
																			,	@OfferBaseBillingRate VARCHAR(50)
																			,	@OfferSpendStretch1Value VARCHAR(50)
																			,	@OfferAboveSpendStretch1MarketingRate VARCHAR(50)
																			,	@OfferAboveSpendStretch1BillingRate VARCHAR(50)
																			,	@OfferSpendStretch2Value VARCHAR(50)
																			,	@OfferAboveSpendStretch2MarketingRate VARCHAR(50)
																			,	@OfferAboveSpendStretch2BillingRate VARCHAR(50)
																			,	@OfferUsesPerCustomer VARCHAR(50)
																			,	@OfferChannel VARCHAR(50)
																			,	@OfferCashbackLimit VARCHAR(50)
																			,	@OfferThrottlePercent VARCHAR(50)
																			,	@OfferForecastedVolumes VARCHAR(50)
																			,	@OfferMinAge VARCHAR(50)
																			,	@OfferMaxAge VARCHAR(50)
																			,	@OfferGender VARCHAR(50)
																			,	@OfferMinSocialClass VARCHAR(50)
																			,	@OfferMaxSocialClass VARCHAR(50)

																			,	@ForecastID VARCHAR(50) = NULL)
--WITH EXECUTE AS 'Rory'
AS
	BEGIN



	/* Testing
	
	DECLARE	@RetailerName VARCHAR(50)
		,	@CampaignCode VARCHAR(50)
		,	@AcquireDefinition VARCHAR(100)
		,	@LapsedDefinition VARCHAR(100)
		,	@ShopperDefinition VARCHAR(100)
		,	@CampaignName VARCHAR(100)
		,	@CampaignRewardType VARCHAR(50)
		,	@CampaignUsesPerCustomer VARCHAR(50)
		,	@CampaignChannel VARCHAR(50)
		,	@CampaignOverride VARCHAR(50)
		,	@CampaignStartDate VARCHAR(50)
		,	@CampaignEndDate VARCHAR(50)
		,	@CampaignCycles VARCHAR(50)
		,	@BespokeCampaign VARCHAR(50)
		,	@BespokeCampaign_Analyst VARCHAR(50)
		,	@BespokeCampaign_PreviousCampaign VARCHAR(50)
		,	@PreviousCampaignToCopyTargetingFrom VARCHAR(50)
		,	@ReplaceExistingOffers VARCHAR(50)
		,	@TakePriorityOverExistingOffers VARCHAR(50)
		,	@AdditionalInformation VARCHAR(MAX)
		,	@BespokeCampaign_BespokeCode VARCHAR(MAX)
		,	@Publisher VARCHAR(100)
		,	@OfferSegment VARCHAR(50)
		,	@IronOfferID VARCHAR(50)
		,	@IronOfferID_AlternateRecord VARCHAR(50)
		,	@OfferName VARCHAR(50)
		,	@OfferStartDate VARCHAR(50)
		,	@OfferEndDate VARCHAR(50)
		,	@OfferBaseMarketingRate VARCHAR(50)
		,	@OfferBaseBillingRate VARCHAR(50)
		,	@OfferSpendStretch1Value VARCHAR(50)
		,	@OfferAboveSpendStretch1MarketingRate VARCHAR(50)
		,	@OfferAboveSpendStretch1BillingRate VARCHAR(50)
		,	@OfferSpendStretch2Value VARCHAR(50)
		,	@OfferAboveSpendStretch2MarketingRate VARCHAR(50)
		,	@OfferAboveSpendStretch2BillingRate VARCHAR(50)
		,	@OfferUsesPerCustomer VARCHAR(50)
		,	@OfferChannel VARCHAR(50)
		,	@OfferCashbackLimit VARCHAR(50)
		,	@OfferThrottlePercent VARCHAR(50)
		,	@OfferForecastedVolumes VARCHAR(50)
		,	@OfferMinAge VARCHAR(50)
		,	@OfferMaxAge VARCHAR(50)
		,	@OfferGender VARCHAR(50)
		,	@OfferMinSocialClass VARCHAR(50)
		,	@OfferMaxSocialClass VARCHAR(50)

		DECLARE @ID INT = 1

		SELECT	@RetailerName = RetailerName
			,	@CampaignCode = CampaignCode
			,	@AcquireDefinition = AcquireDefinition
			,	@LapsedDefinition = LapsedDefinition
			,	@ShopperDefinition = ShopperDefinition
			,	@CampaignName = CampaignName
			,	@CampaignRewardType = CampaignRewardType
			,	@CampaignUsesPerCustomer = CampaignUsesPerCustomer
			,	@CampaignChannel = CampaignChannel
			,	@CampaignOverride = CampaignOverride
			,	@CampaignStartDate = CampaignStartDate
			,	@CampaignEndDate = CampaignEndDate
			,	@CampaignCycles = CampaignCycles
			,	@BespokeCampaign = BespokeCampaign
			,	@BespokeCampaign_Analyst = BespokeCampaign_Analyst
			,	@BespokeCampaign_PreviousCampaign = BespokeCampaign_PreviousCampaign
			,	@PreviousCampaignToCopyTargetingFrom = PreviousCampaignToCopyTargetingFrom
			,	@ReplaceExistingOffers = ReplaceExistingOffers
			,	@TakePriorityOverExistingOffers = TakePriorityOverExistingOffers
			,	@AdditionalInformation = AdditionalInformation
			,	@BespokeCampaign_BespokeCode = BespokeCampaign_BespokeCode
			,	@Publisher = Publisher
			,	@OfferSegment = OfferSegment
			,	@IronOfferID = IronOfferID
			,	@IronOfferID_AlternateRecord = IronOfferID_AlternateRecord
			,	@OfferName = OfferName
			,	@OfferStartDate = OfferStartDate
			,	@OfferEndDate = OfferEndDate
			,	@OfferBaseMarketingRate = OfferBaseMarketingRate
			,	@OfferBaseBillingRate = OfferBaseBillingRate
			,	@OfferSpendStretch1Value = OfferSpendStretch1Value
			,	@OfferAboveSpendStretch1MarketingRate = OfferAboveSpendStretch1MarketingRate
			,	@OfferAboveSpendStretch1BillingRate = OfferAboveSpendStretch1BillingRate
			,	@OfferSpendStretch2Value = OfferSpendStretch2Value
			,	@OfferAboveSpendStretch2MarketingRate = OfferAboveSpendStretch2MarketingRate
			,	@OfferAboveSpendStretch2BillingRate = OfferAboveSpendStretch2BillingRate
			,	@OfferUsesPerCustomer = OfferUsesPerCustomer
			,	@OfferChannel = OfferChannel
			,	@OfferCashbackLimit = OfferCashbackLimit
			,	@OfferThrottlePercent = OfferThrottlePercent
			,	@OfferForecastedVolumes = OfferForecastedVolumes
			,	@OfferMinAge = OfferMinAge
			,	@OfferMaxAge = OfferMaxAge
			,	@OfferGender = OfferGender
			,	@OfferMinSocialClass = OfferMinSocialClass
			,	@OfferMaxSocialClass = OfferMaxSocialClass
		FROM [Selections].[BriefRequestTool_CampaignSetup]
		WHERE ID = @ID

		Testing */

		SELECT	@IronOfferID = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@IronOfferID, ' ', ''), CHAR(0), ''), CHAR(9), ''), CHAR(10), ''), CHAR(11), ''), CHAR(12), ''), CHAR(13), ''), CHAR(14), ''), CHAR(160), ''), CHAR(32), '')
			,	@IronOfferID_AlternateRecord = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@IronOfferID_AlternateRecord, ' ', ''), CHAR(0), ''), CHAR(9), ''), CHAR(10), ''), CHAR(11), ''), CHAR(12), ''), CHAR(13), ''), CHAR(14), ''), CHAR(160), ''), CHAR(32), '')
		
		SELECT	@IronOfferID = COALESCE(TRY_CONVERT(INT, @IronOfferID), '')
			,	@IronOfferID_AlternateRecord = COALESCE(TRY_CONVERT(INT, @IronOfferID_AlternateRecord), '')
			
		SELECT	@IronOfferID = CASE WHEN @IronOfferID = '0' THEN '' ELSE @IronOfferID END
			,	@IronOfferID_AlternateRecord = CASE WHEN @IronOfferID_AlternateRecord = '0' THEN '' ELSE @IronOfferID_AlternateRecord END

		INSERT INTO [Selections].[BriefRequestTool_CampaignSetup_Import] (	RetailerName
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


		SELECT	@RetailerName
			,	@CampaignCode
			,	@AcquireDefinition
			,	@LapsedDefinition
			,	@ShopperDefinition
			,	@CampaignName
			,	@CampaignRewardType
			,	@CampaignUsesPerCustomer
			,	@CampaignChannel
			,	@CampaignOverride
			,	@CampaignStartDate
			,	@CampaignEndDate
			,	@CampaignCycles
			,	@BespokeCampaign
			,	@BespokeCampaign_Analyst
			,	@BespokeCampaign_PreviousCampaign
			,	@PreviousCampaignToCopyTargetingFrom
			,	@ReplaceExistingOffers
			,	@TakePriorityOverExistingOffers
			,	@AdditionalInformation
			,	@BespokeCampaign_BespokeCode
			,	@Publisher
			,	@OfferSegment
			,	@IronOfferID
			,	@IronOfferID_AlternateRecord
			,	@OfferName
			,	@OfferStartDate
			,	@OfferEndDate
			,	@OfferBaseMarketingRate
			,	@OfferBaseBillingRate
			,	@OfferSpendStretch1Value
			,	@OfferAboveSpendStretch1MarketingRate
			,	@OfferAboveSpendStretch1BillingRate
			,	@OfferSpendStretch2Value
			,	@OfferAboveSpendStretch2MarketingRate
			,	@OfferAboveSpendStretch2BillingRate
			,	@OfferUsesPerCustomer
			,	@OfferChannel
			,	@OfferCashbackLimit
			,	@OfferThrottlePercent
			,	@OfferForecastedVolumes
			,	@OfferMinAge
			,	@OfferMaxAge
			,	@OfferGender
			,	@OfferMinSocialClass
			,	@OfferMaxSocialClass
			,	@ForecastID
		WHERE LEN(@OfferSegment) > 0


	END
GO
GRANT EXECUTE
    ON OBJECT::[Selections].[BriefRequestTool_ImportCampaignDetails_Import] TO [ExcelQuery_DataOps]
    AS [dbo];

