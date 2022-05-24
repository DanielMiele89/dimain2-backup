﻿CREATE TABLE [InsightArchive].[QBR_Toolkit_LTV_cust] (
    [IronOfferName]             NVARCHAR (200) NULL,
    [BrandName]                 VARCHAR (100)  NULL,
    [AgeCurrentBandText]        VARCHAR (10)   NULL,
    [Region]                    VARCHAR (30)   NULL,
    [Gender]                    CHAR (1)       NULL,
    [CAMEO_CODE_GROUP_Category] VARCHAR (100)  NOT NULL,
    [Social_Class]              NVARCHAR (255) NULL,
    [period]                    VARCHAR (6)    NULL,
    [spend]                     MONEY          NULL,
    [transactions]              INT            NULL,
    [customers]                 INT            NULL,
    [isonline]                  INT            NULL
);

