CREATE TABLE [Staging].[PartnerizeReportingTransactions] (
    [campaign_id]      VARCHAR (50) NULL,
    [camref]           VARCHAR (50) NULL,
    [conversion_time]  DATETIME     NOT NULL,
    [conversionref]    BIGINT       NULL,
    [country]          VARCHAR (2)  NOT NULL,
    [currency]         VARCHAR (3)  NOT NULL,
    [value]            SMALLMONEY   NOT NULL,
    [commission]       SMALLMONEY   NOT NULL,
    [adref]            VARCHAR (9)  NULL,
    [tsource]          VARCHAR (13) NOT NULL,
    [publisher_id]     INT          NOT NULL,
    [report_month]     INT          NOT NULL,
    [datasource]       VARCHAR (50) NOT NULL,
    [IsReturn]         BIT          DEFAULT ((0)) NOT NULL,
    [SchemeTransMatch] VARCHAR (50) NULL
);

