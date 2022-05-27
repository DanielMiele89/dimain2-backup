CREATE TABLE [Selections].[CampaignSetup_BriefInsert_OfferDetails] (
    [ID]                          INT             IDENTITY (1, 1) NOT NULL,
    [Publisher]                   VARCHAR (255)   NULL,
    [PartnerName]                 VARCHAR (255)   NULL,
    [Override]                    INT             NULL,
    [ClientServicesRef]           VARCHAR (255)   NULL,
    [CampaignStartDate]           DATE            NULL,
    [CampaignEndDate]             DATE            NULL,
    [IronOfferID]                 VARCHAR (255)   NULL,
    [OfferRate]                   DECIMAL (19, 4) NULL,
    [SpendStretchAmount]          DECIMAL (19, 2) NULL,
    [AboveSpendStretchRate]       DECIMAL (19, 4) NULL,
    [OfferBillingRate]            DECIMAL (19, 4) NULL,
    [AboveSpendStrechBillingRate] DECIMAL (19, 4) NULL
);

