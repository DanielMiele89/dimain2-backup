CREATE TABLE [InsightArchive].[Total_YoY_MoM] (
    [TRANDATE]                  DATE         NULL,
    [BrandID]                   SMALLINT     NOT NULL,
    [BrandName]                 VARCHAR (50) NOT NULL,
    [SectorName]                VARCHAR (50) NULL,
    [GroupName]                 VARCHAR (50) NULL,
    [PARTNER_LAST_12_MONTHS]    INT          NOT NULL,
    [TOTAL_SALES]               MONEY        NULL,
    [PREVIOUS_YEAR_TOTAL_SALES] MONEY        NULL
);

