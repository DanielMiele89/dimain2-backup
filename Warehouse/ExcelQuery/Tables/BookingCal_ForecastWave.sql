CREATE TABLE [ExcelQuery].[BookingCal_ForecastWave] (
    [ClientServicesRef]         VARCHAR (40)   NOT NULL,
    [StartDate]                 DATE           NULL,
    [EndDate]                   DATE           NULL,
    [TargetedVolume]            INT            NULL,
    [ControlVolume]             INT            NULL,
    [CustomerBaseType]          INT            NULL,
    [Base]                      INT            NULL,
    [AvgOfferRate]              NUMERIC (7, 4) NULL,
    [TotalSales]                MONEY          NULL,
    [QualyfingSales]            MONEY          NULL,
    [TotalIncrementalSales]     MONEY          NULL,
    [WeeklySpenders]            INT            NULL,
    [TotalSpenders]             INT            NULL,
    [QualyfingSpenders]         INT            NULL,
    [TotalIncrementalSpednders] INT            NULL,
    [TotalCashback]             MONEY          NULL,
    [TotalOverride]             MONEY          NULL,
    [QualyfingCashback]         MONEY          NULL,
    [QualyfingOverride]         MONEY          NULL,
    [LengthWeeks]               INT            NULL,
    [ForecastSubmissionDate]    DATETIME       NULL,
    [RetailerType]              VARCHAR (40)   NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_ClientServicesRef_StartDate]
    ON [ExcelQuery].[BookingCal_ForecastWave]([ClientServicesRef] ASC, [StartDate] ASC, [EndDate] ASC);


GO
CREATE CLUSTERED INDEX [cx_ClientServicesRef_StartDate]
    ON [ExcelQuery].[BookingCal_ForecastWave]([ClientServicesRef] ASC, [StartDate] ASC, [EndDate] ASC) WITH (FILLFACTOR = 95);

