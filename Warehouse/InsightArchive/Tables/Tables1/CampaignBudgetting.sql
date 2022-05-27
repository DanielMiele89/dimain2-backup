CREATE TABLE [InsightArchive].[CampaignBudgetting] (
    [AwarenessLevel]  VARCHAR (10)   NULL,
    [Segment]         NVARCHAR (200) NULL,
    [Publisher]       NVARCHAR (100) NOT NULL,
    [TransactionDate] DATETIME       NULL,
    [PartnerName]     VARCHAR (100)  NULL,
    [PartnerID]       INT            NOT NULL,
    [AccountManager]  VARCHAR (20)   NULL,
    [StartDate]       DATETIME       NULL,
    [EndDate]         DATETIME       NULL,
    [DAYOFWEEK]       NVARCHAR (30)  NULL,
    [TotalSales]      MONEY          NULL,
    [Investment]      MONEY          NULL,
    [Spenders]        INT            NULL,
    [OnOfferPeople]   INT            NULL
);

