CREATE TABLE [Staging].[OfferReport_BaseOfferTable] (
    [CINID]              INT   NULL,
    [IronOfferID]        INT   NOT NULL,
    [IronOfferCyclesID]  INT   NULL,
    [ControlGroupID]     INT   NOT NULL,
    [StartDate]          DATE  NOT NULL,
    [EndDate]            DATE  NOT NULL,
    [Exposed]            BIT   NOT NULL,
    [isWarehouse]        BIT   NULL,
    [PartnerID]          INT   NULL,
    [ControlGroupTypeID] INT   NOT NULL,
    [UpperValue]         MONEY NOT NULL,
    [SpendStretch]       INT   NULL,
    [offerStartDate]     DATE  NOT NULL,
    [offerEndDate]       DATE  NOT NULL
);

