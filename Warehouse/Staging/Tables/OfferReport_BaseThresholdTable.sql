CREATE TABLE [Staging].[OfferReport_BaseThresholdTable] (
    [CINID]              INT   NOT NULL,
    [IronOfferID]        INT   NOT NULL,
    [IronOfferCyclesID]  INT   NULL,
    [ControlGroupID]     INT   NOT NULL,
    [StartDate]          DATE  NOT NULL,
    [EndDate]            DATE  NOT NULL,
    [Exposed]            BIT   NOT NULL,
    [isWarehouse]        BIT   NULL,
    [Sales]              MONEY NULL,
    [Trans]              INT   NULL,
    [Channel]            BIT   NULL,
    [Threshold]          BIT   NULL,
    [PartnerID]          INT   NULL,
    [ControlGroupTypeID] INT   NOT NULL,
    [UpperValue]         MONEY NOT NULL,
    [SpendStretch]       INT   NULL,
    [offerStartDate]     DATE  NOT NULL,
    [offerEndDate]       DATE  NOT NULL
);

