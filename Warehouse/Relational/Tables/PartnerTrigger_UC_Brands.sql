CREATE TABLE [Relational].[PartnerTrigger_UC_Brands] (
    [CampaignID] INT NULL,
    [BrandID]    INT NULL,
    [PTB_ID]     INT IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY CLUSTERED ([PTB_ID] ASC)
);

