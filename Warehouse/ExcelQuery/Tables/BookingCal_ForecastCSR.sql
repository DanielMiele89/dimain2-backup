CREATE TABLE [ExcelQuery].[BookingCal_ForecastCSR] (
    [ClientServicesRef]         VARCHAR (40)   NOT NULL,
    [TargetedVolume]            INT            NULL,
    [AvgOfferRate]              NUMERIC (7, 4) NULL,
    [TotalSales]                MONEY          NULL,
    [TotalIncrementalSales]     MONEY          NULL,
    [TotalCashback]             MONEY          NULL,
    [TotalOverride]             MONEY          NULL,
    [QualyfingSales]            MONEY          NULL,
    [QualyfingIncrementalSales] MONEY          NULL,
    [QualyfingCashback]         MONEY          NULL,
    [QualyfingOverride]         MONEY          NULL,
    [TotalSpenders]             INT            NULL,
    [QualyfingSpenders]         INT            NULL,
    [LengthWeeks]               INT            NULL,
    [ForecastSubmissionDate]    DATETIME       NULL
);

