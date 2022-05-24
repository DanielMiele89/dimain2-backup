CREATE TABLE [InsightArchive].[DWQuarterlyReport_Travel_Sector] (
    [week_commencing]           DATE           NULL,
    [RetailerType]              VARCHAR (20)   NULL,
    [CAMEO_CODE_GROUP]          VARCHAR (2)    NULL,
    [CAMEO_CODE_GROUP_Category] VARCHAR (100)  NULL,
    [Social_Class]              NVARCHAR (255) NULL,
    [IsUKSpend]                 BIT            NOT NULL,
    [Gender]                    CHAR (1)       NULL,
    [Region]                    VARCHAR (30)   NULL,
    [AgeCurrentBandText]        VARCHAR (10)   NULL,
    [DebitTrx]                  INT            NULL,
    [DebitCustomers]            INT            NULL,
    [DebitSpend]                MONEY          NULL,
    [CreditTrx]                 INT            NULL,
    [CreditCustomers]           INT            NULL,
    [CreditSpend]               MONEY          NULL
);

