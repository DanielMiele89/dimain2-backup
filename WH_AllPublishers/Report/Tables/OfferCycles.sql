CREATE TABLE [Report].[OfferCycles] (
    [OfferCyclesID]            INT           IDENTITY (1, 1) NOT NULL,
    [StartDate]                DATETIME2 (7) NOT NULL,
    [EndDate]                  DATETIME2 (7) NOT NULL,
    [Warehouse_OfferCyclesID]  INT           NULL,
    [nFI__OfferCyclesID]       INT           NULL,
    [WH_Virgin__OfferCyclesID] INT           NULL,
    [WH_Visa__OfferCyclesID]   INT           NULL,
    PRIMARY KEY CLUSTERED ([OfferCyclesID] ASC)
);

