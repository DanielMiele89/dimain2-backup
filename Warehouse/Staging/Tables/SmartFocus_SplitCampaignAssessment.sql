CREATE TABLE [Staging].[SmartFocus_SplitCampaignAssessment] (
    [FanID]             INT           NULL,
    [Email]             VARCHAR (100) NULL,
    [WG]                BIT           NULL,
    [Ontrial]           BIT           NULL,
    [Phase1AccountName] VARCHAR (20)  NULL,
    [Phase1Trial]       BIT           NULL,
    [LoyaltyAccount]    BIT           NULL,
    [EmailDate]         DATE          NULL
);


GO
CREATE CLUSTERED INDEX [ix_SmartFocus_SplitCampaignAssessment_EmailDateFanID]
    ON [Staging].[SmartFocus_SplitCampaignAssessment]([EmailDate] ASC, [FanID] ASC) WITH (FILLFACTOR = 80);

