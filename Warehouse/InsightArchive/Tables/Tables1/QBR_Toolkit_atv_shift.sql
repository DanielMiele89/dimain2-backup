CREATE TABLE [InsightArchive].[QBR_Toolkit_atv_shift] (
    [main_brand]        VARCHAR (50) NULL,
    [report_date]       DATETIME     NOT NULL,
    [brandname]         VARCHAR (50) NOT NULL,
    [period_start_date] DATE         NULL,
    [period_end_date]   DATE         NULL,
    [period]            VARCHAR (8)  NULL,
    [spend]             MONEY        NULL,
    [transactions]      INT          NULL,
    [isonline]          INT          NULL
);

