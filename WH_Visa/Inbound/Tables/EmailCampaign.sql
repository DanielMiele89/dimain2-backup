CREATE TABLE [Inbound].[EmailCampaign] (
    [ID]           INT            IDENTITY (1, 1) NOT NULL,
    [CampaignKey]  NVARCHAR (8)   NOT NULL,
    [EmailKey]     NVARCHAR (10)  NULL,
    [CampaignName] NVARCHAR (255) NOT NULL,
    [Subject]      NVARCHAR (255) NULL,
    [SendDate]     DATETIME       NULL,
    CONSTRAINT [pk_CampaignKey] PRIMARY KEY CLUSTERED ([CampaignKey] ASC)
);


GO
GRANT INSERT
    ON OBJECT::[Inbound].[EmailCampaign] TO [crtimport]
    AS [New_DataOps];


GO
GRANT SELECT
    ON OBJECT::[Inbound].[EmailCampaign] TO [crtimport]
    AS [New_DataOps];


GO
GRANT UPDATE
    ON OBJECT::[Inbound].[EmailCampaign] TO [crtimport]
    AS [New_DataOps];

