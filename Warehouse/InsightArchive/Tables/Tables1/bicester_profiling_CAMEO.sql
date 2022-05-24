CREATE TABLE [InsightArchive].[bicester_profiling_CAMEO] (
    [main_brand]                VARCHAR (1)    NULL,
    [BrandName]                 VARCHAR (50)   NULL,
    [Groupname]                 VARCHAR (17)   NULL,
    [TranDate]                  DATE           NULL,
    [Gender]                    CHAR (1)       NULL,
    [CAMEO_CODE_GROUP_Category] VARCHAR (100)  NOT NULL,
    [Social_Class]              NVARCHAR (255) NULL,
    [SPEND]                     MONEY          NULL,
    [TRANSACTIONS]              INT            NULL,
    [CUSTOMERS]                 INT            NULL,
    [TOTAL_COUNT]               INT            NULL,
    [Isonline]                  INT            NULL
);

