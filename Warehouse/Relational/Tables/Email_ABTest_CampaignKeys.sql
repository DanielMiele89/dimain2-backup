CREATE TABLE [Relational].[Email_ABTest_CampaignKeys] (
    [CK_ID]       INT          IDENTITY (1, 1) NOT NULL,
    [CampaignID]  INT          NULL,
    [CampaignKey] NVARCHAR (8) NULL,
    PRIMARY KEY CLUSTERED ([CK_ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_CampaignID]
    ON [Relational].[Email_ABTest_CampaignKeys]([CampaignID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_CampaignKey]
    ON [Relational].[Email_ABTest_CampaignKeys]([CampaignKey] ASC);

