CREATE TABLE [Relational].[PartnerTrigger_Brands] (
    [CampaignID] INT NULL,
    [BrandID]    INT NULL,
    [PTB_ID]     INT IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY CLUSTERED ([PTB_ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_BrandID]
    ON [Relational].[PartnerTrigger_Brands]([BrandID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_CampID]
    ON [Relational].[PartnerTrigger_Brands]([CampaignID] ASC);

