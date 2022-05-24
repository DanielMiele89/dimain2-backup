CREATE TABLE [Derived].[EmailEventsVirginLoad] (
    [EventID]          INT          NOT NULL,
    [EventDateTime]    DATETIME     NOT NULL,
    [EventDate]        DATE         NULL,
    [FanID]            INT          NOT NULL,
    [CompositeID]      BIGINT       NULL,
    [CampaignKey]      NVARCHAR (8) NOT NULL,
    [EmailEventCodeID] INT          NOT NULL,
    [RN]               INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([EventID] ASC) WITH (FILLFACTOR = 70)
);

