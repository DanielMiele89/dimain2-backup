CREATE TABLE [Report].[OfferReport_AllOffers] (
    [ID]                         INT           IDENTITY (1, 1) NOT NULL,
    [OfferID]                    INT           NOT NULL,
    [IronOfferID]                INT           NOT NULL,
    [OfferReportingPeriodsID]    INT           NULL,
    [ControlGroupID]             INT           NOT NULL,
    [IsInPromgrammeControlGroup] BIT           NOT NULL,
    [StartDate]                  DATETIME2 (7) NOT NULL,
    [EndDate]                    DATETIME2 (7) NOT NULL,
    [PartnerID]                  INT           NULL,
    [SpendStretch]               INT           DEFAULT ((0)) NULL,
    [IsPartial]                  BIT           NOT NULL,
    [ReportingDate]              DATE          NULL,
    [PublisherID]                INT           NULL,
    [OfferStartDate]             DATETIME2 (7) NULL,
    [OfferEndDate]               DATETIME2 (7) NULL,
    [BrandID]                    INT           NULL,
    CONSTRAINT [PK_AllOffersID] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_IronStartEnd]
    ON [Report].[OfferReport_AllOffers]([IronOfferID] ASC, [OfferReportingPeriodsID] ASC, [StartDate] ASC, [EndDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SpendStretch]
    ON [Report].[OfferReport_AllOffers]([SpendStretch] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UC_OfferReport_AllOffers]
    ON [Report].[OfferReport_AllOffers]([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC, [IsInPromgrammeControlGroup] ASC);

