CREATE TABLE [Selections].[CampaignSetup] (
    [ID]                         INT           IDENTITY (1, 1) NOT NULL,
    [DatabaseName]               VARCHAR (50)  NULL,
    [CampaignType]               VARCHAR (3)   NULL,
    [EmailDate]                  DATE          NULL,
    [PartnerID]                  CHAR (4)      NULL,
    [StartDate]                  DATE          NULL,
    [EndDate]                    DATE          NULL,
    [CampaignName]               VARCHAR (250) NULL,
    [ClientServicesRef]          VARCHAR (10)  NULL,
    [OfferID]                    VARCHAR (40)  NULL,
    [PriorityFlag]               INT           NULL,
    [PredictedCardholderVolumes] VARCHAR (50)  NULL,
    [Throttling]                 VARCHAR (200) NULL,
    [ThrottleType]               VARCHAR (1)   NULL,
    [RandomThrottle]             BIT           NULL,
    [GSBB]                       VARCHAR (23)  NULL,
    [MarketableByEmail]          VARCHAR (5)   NULL,
    [PaymentMethodsAvailable]    VARCHAR (10)  NULL,
    [Gender]                     CHAR (1)      NULL,
    [AgeRange]                   VARCHAR (7)   NULL,
    [DriveTimeMins]              CHAR (3)      NULL,
    [LiveNearAnyStore]           BIT           NULL,
    [SocialClass]                VARCHAR (5)   NULL,
    [FreqStretch_TransCount]     INT           NULL,
    [CustomerBaseOfferDate]      DATE          NULL,
    [SelectedInAnotherCampaign]  VARCHAR (50)  NULL,
    [DeDupeAgainstCampaigns]     VARCHAR (50)  NULL,
    [CampaignID_Include]         CHAR (3)      NULL,
    [CampaignID_Exclude]         CHAR (3)      NULL,
    [ControlGroupPercentage]     INT           NULL,
    [sProcPreSelection]          VARCHAR (250) NULL,
    [OutputTableName]            VARCHAR (250) NULL,
    [NotIn_TableName1]           VARCHAR (150) NULL,
    [NotIn_TableName2]           VARCHAR (150) NULL,
    [NotIn_TableName3]           VARCHAR (150) NULL,
    [NotIn_TableName4]           VARCHAR (150) NULL,
    [MustBeIn_TableName1]        VARCHAR (250) NULL,
    [MustBeIn_TableName2]        VARCHAR (150) NULL,
    [MustBeIn_TableName3]        VARCHAR (150) NULL,
    [MustBeIn_TableName4]        VARCHAR (150) NULL,
    [BriefLocation]              VARCHAR (250) NULL,
    [CampaignCycleLength_Weeks]  INT           NULL,
    [NewCampaign]                BIT           NULL,
    [BespokeCampaign]            BIT           NULL,
    [ReadyToRun]                 BIT           NULL,
    [SelectionRun]               BIT           NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EmailDate]
    ON [Selections].[CampaignSetup]([EmailDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_OfferID]
    ON [Selections].[CampaignSetup]([OfferID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_StartDate_IncEmailDate]
    ON [Selections].[CampaignSetup]([StartDate] ASC)
    INCLUDE([EmailDate]);

