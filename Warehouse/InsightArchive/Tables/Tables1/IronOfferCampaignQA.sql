CREATE TABLE [InsightArchive].[IronOfferCampaignQA] (
    [IronOfferID]           INT           NOT NULL,
    [PartnerID]             INT           NOT NULL,
    [RetailerID]            INT           NOT NULL,
    [Retailer]              VARCHAR (100) NOT NULL,
    [PublisherID]           INT           NOT NULL,
    [Publisher]             VARCHAR (50)  NOT NULL,
    [PositiveTranCount]     INT           NOT NULL,
    [IronOfferName]         VARCHAR (100) NULL,
    [StartDate]             DATE          NULL,
    [EndDate]               DATE          NULL,
    [IsAppliedToAllMembers] BIT           NULL,
    [AboveBase]             BIT           NULL,
    [CampaignType]          VARCHAR (100) NULL,
    [EndsInPeriod]          BIT           DEFAULT ((0)) NOT NULL,
    [CycleInPeriod]         BIT           NULL,
    [CycleStartDate]        DATE          NULL,
    [CycleEndDate]          DATE          NULL,
    PRIMARY KEY CLUSTERED ([IronOfferID] ASC)
);

