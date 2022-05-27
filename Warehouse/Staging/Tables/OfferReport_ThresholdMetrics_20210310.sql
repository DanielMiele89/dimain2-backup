CREATE TABLE [Staging].[OfferReport_ThresholdMetrics_20210310] (
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
    [isWarehouse]       BIT   NULL
)
WITH (DATA_COMPRESSION = ROW);

