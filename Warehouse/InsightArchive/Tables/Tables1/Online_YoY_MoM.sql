CREATE TABLE [InsightArchive].[Online_YoY_MoM] (
    [TRANDATE]                   DATE         NULL,
    [BrandID]                    SMALLINT     NOT NULL,
    [BrandName]                  VARCHAR (50) NOT NULL,
    [SectorName]                 VARCHAR (50) NULL,
    [GroupName]                  VARCHAR (50) NULL,
    [PARTNER_LAST_12_MONTHS]     INT          NOT NULL,
    [ONLINE_SALES]               MONEY        NULL,
    [PREVIOUS_YEAR_ONLINE_SALES] MONEY        NULL
);

