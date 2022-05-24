CREATE TABLE [Relational].[SMSCampaign] (
    [SMSCampaignID] INT          IDENTITY (1, 1) NOT NULL,
    [CampaignKey]   NVARCHAR (8) NULL,
    [Sent]          BIT          NOT NULL,
    CONSTRAINT [pk_CampaignID] PRIMARY KEY CLUSTERED ([SMSCampaignID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_CK]
    ON [Relational].[SMSCampaign]([CampaignKey] ASC);

