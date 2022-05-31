CREATE TABLE [SamW].[CampaignInsightForecasting] (
    [Segment]            NVARCHAR (200) NULL,
    [AgeCurrentBandText] VARCHAR (10)   NULL,
    [Region]             VARCHAR (30)   NULL,
    [PostCodeDistrict]   VARCHAR (4)    NULL,
    [Social_Class]       NVARCHAR (255) NULL,
    [Publisher]          NVARCHAR (100) NOT NULL,
    [TransactionDate]    DATETIME       NULL,
    [PartnerName]        VARCHAR (100)  NULL,
    [PartnerID]          INT            NOT NULL,
    [AccountManager]     VARCHAR (20)   NULL,
    [StartDate]          DATETIME       NULL,
    [EndDate]            DATETIME       NULL,
    [DAYOFWEEK]          NVARCHAR (30)  NULL,
    [TotalSales]         BIGINT         NULL,
    [Investment]         BIGINT         NULL,
    [Spenders]           BIGINT         NULL,
    [OnOfferPeople]      BIGINT         NULL
);

