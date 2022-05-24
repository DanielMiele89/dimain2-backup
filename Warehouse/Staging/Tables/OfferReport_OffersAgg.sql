CREATE TABLE [Staging].[OfferReport_OffersAgg] (
    [PartnerID]          INT  NOT NULL,
    [IronOfferCyclesID]  INT  NULL,
    [StartDate]          DATE NULL,
    [EndDate]            DATE NULL,
    [ControlGroupID]     INT  NULL,
    [ControlGroupTypeID] INT  NOT NULL,
    [isWarehouse]        BIT  NULL,
    [OfferID]            INT  NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_OffersAggID]
    ON [Staging].[OfferReport_OffersAgg]([OfferID] ASC, [PartnerID] ASC, [IronOfferCyclesID] ASC, [ControlGroupTypeID] ASC);

