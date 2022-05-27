CREATE TABLE [Report].[OfferReport_ThresholdMetrics] (
    [OfferID]                 INT           NOT NULL,
    [IronOfferID]             INT           NOT NULL,
    [Exposed]                 BIT           NOT NULL,
    [OfferReportingPeriodsID] INT           NULL,
    [ControlGroupID]          INT           NULL,
    [StartDate]               DATETIME2 (7) NULL,
    [EndDate]                 DATETIME2 (7) NULL,
    [Channel]                 BIT           NULL,
    [CINID]                   INT           NOT NULL,
    [Sales]                   MONEY         NULL,
    [Trans]                   INT           NULL,
    [Spenders]                INT           NULL,
    [Threshold]               BIT           NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_Channel]
    ON [Report].[OfferReport_ThresholdMetrics]([Channel] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Iron]
    ON [Report].[OfferReport_ThresholdMetrics]([OfferID] ASC, [IronOfferID] ASC)
    INCLUDE([Threshold]);

