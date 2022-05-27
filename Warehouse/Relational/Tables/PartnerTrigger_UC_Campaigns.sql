CREATE TABLE [Relational].[PartnerTrigger_UC_Campaigns] (
    [CampaignID]            INT           NOT NULL,
    [PartnerID]             INT           NULL,
    [CampaignName]          VARCHAR (150) NULL,
    [DaysWorthTransactions] INT           NULL,
    [WeeklyExecute]         BIT           NULL,
    CONSTRAINT [pk_CampaignID3] PRIMARY KEY CLUSTERED ([CampaignID] ASC)
);

