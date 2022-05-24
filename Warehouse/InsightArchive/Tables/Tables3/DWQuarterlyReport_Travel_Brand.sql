CREATE TABLE [InsightArchive].[DWQuarterlyReport_Travel_Brand] (
    [week_commencing]           DATE           NULL,
    [BrandName]                 VARCHAR (50)   NOT NULL,
    [RetailerType]              VARCHAR (20)   NULL,
    [CAMEO_CODE_GROUP]          VARCHAR (2)    NULL,
    [CAMEO_CODE_GROUP_Category] VARCHAR (100)  NULL,
    [Social_Class]              NVARCHAR (255) NULL,
    [IsOnline]                  BIT            NOT NULL,
    [IsUKSpend]                 BIT            NOT NULL,
    [Region]                    VARCHAR (30)   NULL,
    [AgeCurrentBandText]        VARCHAR (10)   NULL,
    [DebitTrx]                  INT            NULL,
    [DebitCustomers]            INT            NULL,
    [DebitSpend]                MONEY          NULL,
    [CreditTrx]                 INT            NULL,
    [CreditCustomers]           INT            NULL,
    [CreditSpend]               MONEY          NULL
);

