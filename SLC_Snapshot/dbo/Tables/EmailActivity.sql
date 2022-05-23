CREATE TABLE [dbo].[EmailActivity] (
    [ID]              INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [EmailCampaignID] INT      NOT NULL,
    [FanID]           INT      NOT NULL,
    [DeliveryDate]    DATETIME NOT NULL,
    [OpenDate]        DATETIME NULL,
    [ClickDate]       DATETIME NULL,
    [UnsubscribeDate] DATETIME NULL,
    [HardBounceDate]  DATETIME NULL,
    [SoftBounceDate]  DATETIME NULL,
    CONSTRAINT [PK_EmailActivity] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 95)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [dbo].[EmailActivity]([FanID] ASC)
    INCLUDE([EmailCampaignID], [OpenDate]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_Stuff2]
    ON [dbo].[EmailActivity]([EmailCampaignID] ASC, [FanID] ASC)
    INCLUDE([OpenDate]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
GRANT SELECT
    ON OBJECT::[dbo].[EmailActivity] TO [PII_Removed]
    AS [dbo];

