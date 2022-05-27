CREATE TABLE [Relational].[PartnerTrigger_Campaigns] (
    [CampaignID]            INT           IDENTITY (1, 1) NOT NULL,
    [PartnerID]             INT           NULL,
    [CampaignName]          VARCHAR (150) NULL,
    [DaysWorthTransactions] INT           NULL,
    [WeeklyExecute]         BIT           NULL,
    CONSTRAINT [pk_CampaignID2] PRIMARY KEY CLUSTERED ([CampaignID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_PartnerID]
    ON [Relational].[PartnerTrigger_Campaigns]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_DWT]
    ON [Relational].[PartnerTrigger_Campaigns]([DaysWorthTransactions] ASC);

