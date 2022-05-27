CREATE TABLE [InsightArchive].[DDForecastStaging_ForecastDetails] (
    [ForecastID]         INT            NOT NULL,
    [ForecastDate]       DATETIME       NOT NULL,
    [brandid]            INT            NULL,
    [brandname]          NVARCHAR (50)  NULL,
    [cohorts]            INT            NULL,
    [cohort_throttle]    NVARCHAR (100) NULL,
    [daysbetweencohorts] INT            NULL,
    [startdate]          DATE           NULL,
    [enddate]            DATE           NULL,
    [postperiod_first]   INT            NULL,
    [postperiod_second]  INT            NULL,
    [exclusion]          INT            NULL,
    [household]          BIT            NULL,
    [override]           FLOAT (53)     NULL,
    [threshold]          NVARCHAR (500) NULL,
    [rates]              NVARCHAR (500) NULL,
    [tablenames]         NVARCHAR (600) NULL,
    [CustomerCount]      INT            NULL
);

