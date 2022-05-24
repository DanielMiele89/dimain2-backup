CREATE TABLE [Inbound].[EmailCampaign] (
    [ID]           INT            IDENTITY (1, 1) NOT NULL,
    [CampaignKey]  NVARCHAR (10)  NOT NULL,
    [EmailKey]     NVARCHAR (10)  NULL,
    [CampaignName] NVARCHAR (255) NOT NULL,
    [Subject]      NVARCHAR (255) NULL,
    [SendDate]     DATETIME       NULL,
    CONSTRAINT [pk_CampaignKey] PRIMARY KEY CLUSTERED ([CampaignKey] ASC)
);

