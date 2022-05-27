CREATE TABLE [InsightArchive].[QBR_Toolkit_demo_profiling_AGE] (
    [main_brand]         VARCHAR (50) NULL,
    [report_date]        DATETIME     NOT NULL,
    [BrandName]          VARCHAR (50) NOT NULL,
    [period_start_date]  DATE         NULL,
    [period_end_date]    DATE         NULL,
    [PERIOD]             VARCHAR (8)  NULL,
    [AgeCurrentBandText] VARCHAR (10) NULL,
    [GENDER]             CHAR (1)     NULL,
    [SPEND]              MONEY        NULL,
    [TRANSACTIONS]       INT          NULL,
    [CUSTOMERS]          INT          NULL,
    [TOTAL_COUNT]        INT          NULL,
    [Isonline]           INT          NULL
);

