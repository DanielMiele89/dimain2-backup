CREATE TABLE [SamW].[FullCampaign] (
    [AwarenessLevel]        VARCHAR (10)    NULL,
    [Segment]               NVARCHAR (200)  NULL,
    [Publisher]             NVARCHAR (100)  NOT NULL,
    [PartnerName]           VARCHAR (100)   NULL,
    [PartnerID]             INT             NOT NULL,
    [AccountManager]        VARCHAR (20)    NULL,
    [StartDate]             DATETIME        NULL,
    [EndDate]               DATETIME        NULL,
    [FullCampaignLength]    INT             NULL,
    [UpToDate]              DATE            NULL,
    [InvestmentSoFar]       MONEY           NULL,
    [InvestmentByDayTotals] NUMERIC (38, 5) NULL
);

