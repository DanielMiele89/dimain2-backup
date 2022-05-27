CREATE TABLE [InsightArchive].[QBR_Toolkit_LTV_MFDD] (
    [IronOfferName]             NVARCHAR (4000) NOT NULL,
    [BrandName]                 VARCHAR (100)   NULL,
    [AgeCurrentBandText]        VARCHAR (10)    NULL,
    [Region]                    VARCHAR (30)    NULL,
    [Gender]                    CHAR (1)        NULL,
    [CAMEO_CODE_GROUP_Category] VARCHAR (100)   NOT NULL,
    [Social_Class]              NVARCHAR (255)  NULL,
    [trans_month]               INT             NULL,
    [redemption_month]          NVARCHAR (4000) NULL,
    [period]                    VARCHAR (6)     NULL,
    [spend]                     MONEY           NULL,
    [transactions]              INT             NULL
);

