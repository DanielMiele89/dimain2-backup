CREATE TABLE [Derived].[EmailCampaignVirgin] (
    [ID]           INT            NOT NULL,
    [CampaignKey]  NVARCHAR (8)   NOT NULL,
    [EmailKey]     NVARCHAR (8)   NULL,
    [CampaignName] NVARCHAR (255) NOT NULL,
    [Subject]      NVARCHAR (255) NULL,
    [SendDateTime] DATETIME       NOT NULL,
    [SendDate]     DATE           NULL,
    CONSTRAINT [pk_CampaignKey_EmailCapaignVirgin] PRIMARY KEY CLUSTERED ([CampaignKey] ASC)
);

