CREATE TABLE [Derived].[EmailCampaign] (
    [ID]           INT            IDENTITY (1, 1) NOT NULL,
    [CampaignKey]  NVARCHAR (8)   NOT NULL,
    [EmailKey]     NVARCHAR (8)   NULL,
    [CampaignName] NVARCHAR (255) NOT NULL,
    [Subject]      NVARCHAR (255) NULL,
    [SendDateTime] DATETIME       NOT NULL,
    [SendDate]     DATE           NULL,
    CONSTRAINT [pk_CampaignKey] PRIMARY KEY CLUSTERED ([CampaignKey] ASC)
);




GO
GRANT SELECT
    ON OBJECT::[Derived].[EmailCampaign] TO [virgin_etl_user]
    AS [dbo];

