CREATE TABLE [Relational].[PartnerTrigger_Campaigns_History] (
    [CampaignID]            INT           NOT NULL,
    [PartnerID]             INT           NULL,
    [CampaignName]          VARCHAR (150) NULL,
    [DaysWorthTransactions] INT           NULL,
    [WeeklyExecute]         BIT           NULL,
    PRIMARY KEY CLUSTERED ([CampaignID] ASC)
);

