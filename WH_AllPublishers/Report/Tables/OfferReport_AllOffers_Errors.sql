CREATE TABLE [Report].[OfferReport_AllOffers_Errors] (
    [ID]                      INT           IDENTITY (1, 1) NOT NULL,
    [OfferID]                 INT           NOT NULL,
    [IronOfferID]             INT           NOT NULL,
    [OfferReportingPeriodsID] INT           NULL,
    [ControlGroupID]          INT           NOT NULL,
    [OfferStartDate]          DATE          NOT NULL,
    [OfferEndDate]            DATE          NOT NULL,
    [ErrorNotes]              VARCHAR (200) NULL,
    CONSTRAINT [PK_AllOfferErrorID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

