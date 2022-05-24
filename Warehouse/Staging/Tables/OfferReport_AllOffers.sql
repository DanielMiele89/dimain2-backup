CREATE TABLE [Staging].[OfferReport_AllOffers] (
    [ID]                 INT  IDENTITY (1, 1) NOT NULL,
    [IronOfferID]        INT  NOT NULL,
    [IronOfferCyclesID]  INT  NULL,
    [ControlGroupID]     INT  NOT NULL,
    [ControlGroupTypeID] INT  NOT NULL,
    [StartDate]          DATE NOT NULL,
    [EndDate]            DATE NOT NULL,
    [PartnerID]          INT  NULL,
    [SpendStretch]       INT  NULL,
    [IsPartial]          BIT  NOT NULL,
    [ReportingDate]      DATE NULL,
    [PublisherID]        INT  NULL,
    [offerStartDate]     DATE NOT NULL,
    [offerEndDate]       DATE NOT NULL,
    [BrandID]            INT  NULL,
    [isWarehouse]        BIT  NULL,
    [IsVirgin]           BIT  NULL,
    [IsVirginPCA]        BIT  NULL,
    [IsVisaBarclaycard]  BIT  NULL,
    CONSTRAINT [PK_AllOffersID] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_IronStartEnd]
    ON [Staging].[OfferReport_AllOffers]([StartDate] ASC, [EndDate] ASC, [IronOfferID] ASC, [IronOfferCyclesID] ASC, [ControlGroupTypeID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [NIX_AllOffers_Main]
    ON [Staging].[OfferReport_AllOffers]([PartnerID] ASC)
    INCLUDE([ControlGroupID], [IronOfferCyclesID], [StartDate], [EndDate], [SpendStretch]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [ofDates]
    ON [Staging].[OfferReport_AllOffers]([offerStartDate] ASC, [offerEndDate] ASC) WITH (FILLFACTOR = 90);

