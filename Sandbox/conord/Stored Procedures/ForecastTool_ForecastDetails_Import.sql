
/******************************************************************************
Author: Sam Weber
Created: 08/11/2021
Purpose: 
	- Importing Forecasts into SQL
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/

CREATE PROCEDURE [ConorD].[ForecastTool_ForecastDetails_Import] (					@PublisherID VARCHAR(50)
																			,	@BrandID VARCHAR(50)
																			,	@RetailerName VARCHAR(100)
																			,	@PublisherName VARCHAR(100)
																			,	@Segment VARCHAR(100)
																			,	@Above VARCHAR(100)
																			,	@SpendStretch VARCHAR(50)
																			,	@Below VARCHAR(50)
																			,	@Bounty VARCHAR(50)
																			,	@OfferType VARCHAR(50)
																			,	@Spend VARCHAR(50)
																			,	@Transactions VARCHAR(50)
																			,	@Customers VARCHAR(50)
																			,	@Investment VARCHAR(50)
																			,	@CycleStartDate VARCHAR(50)
																			,	@CycleEndDate VARCHAR(50)
																			,	@HalfCycleStart VARCHAR(50)
																			,	@HalfCycleEnd VARCHAR(50)
																			,	@ForecastID VARCHAR(50) --ADDED THIS COLUMN TO SANDBOX AND PROCEDURE

																			)
--WITH EXECUTE AS 'ExcelQuery_DataOps'
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
		
		INSERT INTO [ConorD].[ForecastingBudgetTracking_Import] (	PublisherID
															,	BrandID
															,	RetailerName
															,	PublisherName
															,	Segment
															,	Above
															,	SpendStretch
															,	Below
															,	Bounty
															,	OfferType
															,	Spend
															,	Transactions
															,	Customers
															,	Investment
															,	CycleStartDate
															,	CycleEndDate
															,	HalfCycleStart
															,	HalfCycleEnd
															,	ForecastID --ADDED THIS COLUMN TO SANDBOX AND PROCEDURE
															)
		SELECT	@PublisherID
			,	@BrandID
			,	@RetailerName
			,	@PublisherName
			,	@Segment
			,	@Above
			,	@SpendStretch
			,	@Below
			,	@Bounty
			,	@OfferType
			,	@Spend
			,	@Transactions
			,	@Customers
			,	@Investment
			,	@CycleStartDate
			,	@CycleEndDate
			,	@HalfCycleStart
			,	@HalfCycleEnd
			,	@ForecastID --ADDED THIS COLUMN TO SANDBOX AND PROCEDURE
		WHERE LEN(@CycleEndDate) > 5
		
	
	END
