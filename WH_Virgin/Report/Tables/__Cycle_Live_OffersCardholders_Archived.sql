CREATE TABLE [Report].[__Cycle_Live_OffersCardholders_Archived] (
    [ID]               INT           IDENTITY (1, 1) NOT NULL,
    [ReportDate]       DATE          NOT NULL,
    [CycleStart]       DATE          NOT NULL,
    [CycleEnd]         DATE          NOT NULL,
    [ClubID]           INT           NOT NULL,
    [PartnerID]        INT           NOT NULL,
    [IronOfferID]      INT           NOT NULL,
    [IsBaseOffer]      BIT           NOT NULL,
    [CampaignCode]     VARCHAR (100) NULL,
    [Cardholders]      INT           NULL,
    [IronOfferName]    VARCHAR (150) NULL,
    [OfferStartDate]   DATE          NULL,
    [OfferEndDate]     DATE          NULL,
    [BaseRate]         FLOAT (53)    NULL,
    [SpendStretch]     MONEY         NULL,
    [SpendStretchRate] FLOAT (53)    NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

