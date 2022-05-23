CREATE TABLE [dbo].[EmailEvent] (
    [ID]               INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Date]             DATETIME     NOT NULL,
    [FanID]            INT          NOT NULL,
    [CampaignKey]      NVARCHAR (8) NOT NULL,
    [EmailEventCodeID] INT          NOT NULL,
    [ImportedDate]     DATETIME     NOT NULL,
    [Processed]        BIT          NOT NULL,
    CONSTRAINT [PK_EmailEvent] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 95)
);


GO
CREATE NONCLUSTERED INDEX [ix_EmailEventCodeID]
    ON [dbo].[EmailEvent]([EmailEventCodeID] ASC)
    INCLUDE([Date], [FanID]) WITH (FILLFACTOR = 80)
    ON [SLC_REPL_Indexes];


GO
GRANT SELECT
    ON OBJECT::[dbo].[EmailEvent] TO [Analyst]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[EmailEvent] TO [PII_Removed]
    AS [dbo];

