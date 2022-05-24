CREATE TABLE [Report].[__Weekly_Card_Redemptions_Archived] (
    [ID]                    INT           IDENTITY (1, 1) NOT NULL,
    [ReportDate]            DATE          NULL,
    [WeekStart]             DATE          NULL,
    [WeekEnd]               DATE          NULL,
    [WeekID]                INT           NULL,
    [PartnerID]             INT           NULL,
    [RedemptionDescription] VARCHAR (200) NULL,
    [Redemptions]           INT           NULL,
    [CurrentStockLevel]     INT           NULL,
    CONSTRAINT [PK_Weekly_Card_Redemptions] PRIMARY KEY CLUSTERED ([ID] ASC)
);

