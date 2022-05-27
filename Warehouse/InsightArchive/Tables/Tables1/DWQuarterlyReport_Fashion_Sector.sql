CREATE TABLE [InsightArchive].[DWQuarterlyReport_Fashion_Sector] (
    [week_commencing]           DATE           NULL,
    [RetailerType]              VARCHAR (30)   NULL,
    [CAMEO_CODE_GROUP]          VARCHAR (2)    NULL,
    [CAMEO_CODE_GROUP_Category] VARCHAR (100)  NULL,
    [Social_Class]              NVARCHAR (255) NULL,
    [IsOnline]                  BIT            NOT NULL,
    [Gender]                    CHAR (1)       NULL,
    [Region]                    VARCHAR (30)   NULL,
    [AgeCurrentBandText]        VARCHAR (10)   NULL,
    [NumTransaction]            INT            NULL,
    [SalesAmt]                  MONEY          NULL,
    [NumCustomers]              INT            NULL
);

