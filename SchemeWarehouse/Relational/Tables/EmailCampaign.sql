CREATE TABLE [Relational].[EmailCampaign] (
    [CampaignKey]     NVARCHAR (8)   NOT NULL,
    [CampaignName]    NVARCHAR (255) NOT NULL,
    [SendDate]        DATETIME       NULL,
    [EmailsSent]      INT            NULL,
    [EmailsDelivered] INT            NULL,
    PRIMARY KEY CLUSTERED ([CampaignKey] ASC),
    UNIQUE NONCLUSTERED ([CampaignKey] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EmailCampaign_SendDate]
    ON [Relational].[EmailCampaign]([SendDate] ASC);

