CREATE TABLE [Relational].[EmailEvent] (
    [EmailEventID]     INT          NOT NULL,
    [EventDate]        DATETIME     NOT NULL,
    [FanID]            INT          NOT NULL,
    [CampaignKey]      NVARCHAR (8) NOT NULL,
    [EmailEventCodeID] INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([EmailEventID] ASC),
    UNIQUE NONCLUSTERED ([EmailEventID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EmailEvent_FanID]
    ON [Relational].[EmailEvent]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EmailEvent_CampaignKey]
    ON [Relational].[EmailEvent]([CampaignKey] ASC);

