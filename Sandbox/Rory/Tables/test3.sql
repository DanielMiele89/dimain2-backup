CREATE TABLE [Rory].[test3] (
    [IronOfferID]        INT   NOT NULL,
    [IronOfferCyclesID]  INT   NULL,
    [ControlGroupTypeID] INT   NOT NULL,
    [StartDate]          DATE  NOT NULL,
    [EndDate]            DATE  NOT NULL,
    [Channel]            INT   NULL,
    [Sales]              MONEY NULL,
    [Trans]              INT   NULL,
    [ThresholdTrans]     INT   NULL,
    [Spenders]           INT   NULL,
    [Threshold]          INT   NULL,
    [Exposed]            BIT   NOT NULL,
    [offerStartDate]     DATE  NOT NULL,
    [offerEndDate]       DATE  NOT NULL,
    [PartnerID]          INT   NULL,
    [IsWarehouse]        BIT   NULL,
    [IsVirgin]           BIT   NULL,
    [IsVisaBarclaycard]  BIT   NULL
);

