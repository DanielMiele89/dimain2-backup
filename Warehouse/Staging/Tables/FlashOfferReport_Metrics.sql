CREATE TABLE [Staging].[FlashOfferReport_Metrics] (
    [ID]                  INT          IDENTITY (1, 1) NOT NULL,
    [IronOfferID]         INT          NULL,
    [Exposed]             BIT          NULL,
    [StartDate]           DATE         NULL,
    [EndDate]             DATE         NULL,
    [PeriodType]          VARCHAR (25) NULL,
    [Channel]             INT          NULL,
    [Cardholders]         INT          NULL,
    [Sales]               MONEY        NULL,
    [Trans]               INT          NULL,
    [Spenders]            INT          NULL,
    [Threshold]           MONEY        NULL,
    [OfferSetupStartDate] DATE         NULL,
    [OfferSetupEndDate]   DATE         NULL,
    [PartnerID]           INT          NULL,
    [isWarehouse]         BIT          NULL,
    [ControlGroupTypeID]  INT          NULL,
    [CalculationDate]     DATE         NOT NULL,
    CONSTRAINT [PK_FlashOfferReport_Metrics] PRIMARY KEY CLUSTERED ([ID] ASC)
);

