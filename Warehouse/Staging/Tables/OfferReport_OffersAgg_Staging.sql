CREATE TABLE [Staging].[OfferReport_OffersAgg_Staging] (
    [Rnk]                BIGINT NULL,
    [PartnerID]          INT    NOT NULL,
    [IronOfferCyclesID]  INT    NULL,
    [StartDate]          DATE   NULL,
    [EndDate]            DATE   NULL,
    [ControlGroupID]     INT    NULL,
    [ControlGroupTypeID] INT    NOT NULL,
    [isWarehouse]        BIT    NULL,
    [OfferID]            INT    NOT NULL
);

