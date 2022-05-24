CREATE TABLE [Selections].[AllPublisher_CampaignDetails] (
    [ID]                          INT           IDENTITY (1, 1) NOT NULL,
    [ClubID]                      INT           NULL,
    [PartnerName]                 VARCHAR (500) NULL,
    [Override]                    FLOAT (53)    NULL,
    [ClientServicesRef]           VARCHAR (500) NULL,
    [CampaignStartDate]           DATE          NULL,
    [CampaignEndDate]             DATE          NULL,
    [IronOfferID]                 INT           NULL,
    [OfferRate]                   FLOAT (53)    NULL,
    [SpendStretchAmount]          FLOAT (53)    NULL,
    [AboveSpendStretchRate]       FLOAT (53)    NULL,
    [OfferBillingRate]            FLOAT (53)    NULL,
    [AboveSpendStrechBillingRate] FLOAT (53)    NULL
);

