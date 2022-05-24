CREATE TABLE [Report].[IronOfferCycles] (
    [IronOfferCyclesID]       INT IDENTITY (1, 1) NOT NULL,
    [IronOfferID]             INT NOT NULL,
    [OfferCyclesID]           INT NOT NULL,
    [ControlGroupID]          INT NOT NULL,
    [OfferReportingPeriodsID] INT NULL,
    PRIMARY KEY CLUSTERED ([IronOfferCyclesID] ASC)
);

