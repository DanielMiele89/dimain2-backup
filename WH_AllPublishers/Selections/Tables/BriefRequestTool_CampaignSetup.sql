CREATE TABLE [Selections].[BriefRequestTool_CampaignSetup] (
    [ID]                                   INT           IDENTITY (1, 1) NOT NULL,
    [RetailerName]                         VARCHAR (50)  NULL,
    [CampaignCode]                         VARCHAR (50)  NULL,
    [AcquireDefinition]                    VARCHAR (100) NULL,
    [LapsedDefinition]                     VARCHAR (100) NULL,
    [ShopperDefinition]                    VARCHAR (100) NULL,
    [CampaignName]                         VARCHAR (100) NULL,
    [CampaignRewardType]                   VARCHAR (50)  NULL,
    [CampaignUsesPerCustomer]              VARCHAR (50)  NULL,
    [CampaignChannel]                      VARCHAR (50)  NULL,
    [CampaignOverride]                     VARCHAR (50)  NULL,
    [CampaignStartDate]                    VARCHAR (50)  NULL,
    [CampaignEndDate]                      VARCHAR (50)  NULL,
    [CampaignCycles]                       VARCHAR (50)  NULL,
    [BespokeCampaign]                      VARCHAR (50)  NULL,
    [BespokeCampaign_Analyst]              VARCHAR (50)  NULL,
    [BespokeCampaign_PreviousCampaign]     VARCHAR (50)  NULL,
    [PreviousCampaignToCopyTargetingFrom]  VARCHAR (50)  NULL,
    [ReplaceExistingOffers]                VARCHAR (50)  NULL,
    [TakePriorityOverExistingOffers]       VARCHAR (50)  NULL,
    [AdditionalInformation]                VARCHAR (MAX) NULL,
    [BespokeCampaign_BespokeCode]          VARCHAR (MAX) NULL,
    [Publisher]                            VARCHAR (100) NULL,
    [OfferSegment]                         VARCHAR (50)  NULL,
    [IronOfferID]                          VARCHAR (50)  NULL,
    [IronOfferID_AlternateRecord]          VARCHAR (50)  NULL,
    [OfferName]                            VARCHAR (50)  NULL,
    [OfferStartDate]                       VARCHAR (50)  NULL,
    [OfferEndDate]                         VARCHAR (50)  NULL,
    [OfferBaseMarketingRate]               VARCHAR (50)  NULL,
    [OfferBaseBillingRate]                 VARCHAR (50)  NULL,
    [OfferSpendStretch1Value]              VARCHAR (50)  NULL,
    [OfferAboveSpendStretch1MarketingRate] VARCHAR (50)  NULL,
    [OfferAboveSpendStretch1BillingRate]   VARCHAR (50)  NULL,
    [OfferSpendStretch2Value]              VARCHAR (50)  NULL,
    [OfferAboveSpendStretch2MarketingRate] VARCHAR (50)  NULL,
    [OfferAboveSpendStretch2BillingRate]   VARCHAR (50)  NULL,
    [OfferUsesPerCustomer]                 VARCHAR (50)  NULL,
    [OfferChannel]                         VARCHAR (50)  NULL,
    [OfferCashbackLimit]                   VARCHAR (50)  NULL,
    [OfferThrottlePercent]                 VARCHAR (50)  NULL,
    [OfferForecastedVolumes]               VARCHAR (50)  NULL,
    [OfferMinAge]                          VARCHAR (50)  NULL,
    [OfferMaxAge]                          VARCHAR (50)  NULL,
    [OfferGender]                          VARCHAR (50)  NULL,
    [OfferMinSocialClass]                  VARCHAR (50)  NULL,
    [OfferMaxSocialClass]                  VARCHAR (50)  NULL,
    [ForecastID]                           VARCHAR (50)  NULL,
    [RetailerID]                           INT           NULL,
    [PartnerID]                            INT           NULL,
    [PublisherID]                          INT           NULL
);




GO
GRANT VIEW DEFINITION
    ON OBJECT::[Selections].[BriefRequestTool_CampaignSetup] TO [SamW]
    AS [dbo];


GO
GRANT VIEW DEFINITION
    ON OBJECT::[Selections].[BriefRequestTool_CampaignSetup] TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[Selections].[BriefRequestTool_CampaignSetup] TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Selections].[BriefRequestTool_CampaignSetup] TO [SamW]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Selections].[BriefRequestTool_CampaignSetup] TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT REFERENCES
    ON OBJECT::[Selections].[BriefRequestTool_CampaignSetup] TO [SamW]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Selections].[BriefRequestTool_CampaignSetup] TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[Selections].[BriefRequestTool_CampaignSetup] TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT ALTER
    ON OBJECT::[Selections].[BriefRequestTool_CampaignSetup] TO [ExcelQuery_DataOps]
    AS [dbo];

