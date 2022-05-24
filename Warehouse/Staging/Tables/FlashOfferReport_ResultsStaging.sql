CREATE TABLE [Staging].[FlashOfferReport_ResultsStaging] (
    [IronOfferID]         INT          NOT NULL,
    [Exposed]             INT          NOT NULL,
    [StartDate]           DATE         NOT NULL,
    [EndDate]             DATE         NOT NULL,
    [PeriodType]          VARCHAR (25) NOT NULL,
    [Channel]             INT          NULL,
    [Cardholders]         INT          NULL,
    [Sales]               MONEY        NULL,
    [Trans]               INT          NULL,
    [Spenders]            INT          NULL,
    [Threshold]           INT          NULL,
    [OfferSetupStartDate] DATE         NOT NULL,
    [OfferSetupEndDate]   DATE         NULL,
    [PartnerID]           INT          NULL,
    [isWarehouse]         INT          NULL,
    [ControlGroupTypeID]  INT          NULL
);

