CREATE TABLE [Staging].[OfferReport_ThresholdMetrics] (
    [CINID]             INT   NOT NULL,
    [IronOfferID]       INT   NOT NULL,
    [IronOfferCyclesID] INT   NULL,
    [ControlGroupID]    INT   NULL,
    [StartDate]         DATE  NULL,
    [EndDate]           DATE  NULL,
    [Channel]           BIT   NULL,
    [Sales]             MONEY NULL,
    [Trans]             INT   NULL,
    [Spenders]          INT   NULL,
    [Threshold]         BIT   NULL,
    [Exposed]           BIT   NOT NULL,
    [IsWarehouse]       BIT   NULL,
    [IsVirgin]          BIT   NULL,
    [IsVirginPCA]       BIT   NULL,
    [IsVisaBarclaycard] BIT   NULL,
    [PublisherID]       INT   NULL
);


GO
CREATE CLUSTERED INDEX [CIX_CINDate]
    ON [Staging].[OfferReport_ThresholdMetrics]([CINID] ASC, [StartDate] ASC, [EndDate] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Channel]
    ON [Staging].[OfferReport_ThresholdMetrics]([Channel] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Iron]
    ON [Staging].[OfferReport_ThresholdMetrics]([IronOfferID] ASC, [IsWarehouse] ASC, [IsVirgin] ASC, [IsVirginPCA] ASC, [IsVisaBarclaycard] ASC)
    INCLUDE([Threshold]) WITH (FILLFACTOR = 90);

