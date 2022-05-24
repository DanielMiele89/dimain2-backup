CREATE TABLE [Relational].[EmailEvent] (
    [EventID]          INT          NOT NULL,
    [EventDateTime]    DATETIME     NOT NULL,
    [EventDate]        DATE         NULL,
    [FanID]            INT          NOT NULL,
    [CompositeID]      BIGINT       NULL,
    [CampaignKey]      NVARCHAR (8) NOT NULL,
    [EmailEventCodeID] INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([EventID] ASC) WITH (FILLFACTOR = 70, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Relational].[EmailEvent]([FanID] ASC) WITH (FILLFACTOR = 70, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [IDX_Camp]
    ON [Relational].[EmailEvent]([CampaignKey] ASC)
    INCLUDE([FanID]) WITH (FILLFACTOR = 70, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

