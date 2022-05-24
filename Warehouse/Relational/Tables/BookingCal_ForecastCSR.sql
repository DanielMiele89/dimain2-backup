CREATE TABLE [Relational].[BookingCal_ForecastCSR] (
    [ID]                         INT            IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef]          VARCHAR (40)   NOT NULL,
    [TargetedVolume]             INT            NULL,
    [AvgOfferRate]               NUMERIC (7, 4) NULL,
    [TotalSales]                 MONEY          NULL,
    [TotalIncrementalSales]      MONEY          NULL,
    [TotalCashback]              MONEY          NULL,
    [TotalOverride]              MONEY          NULL,
    [QualifyingSales]            MONEY          NULL,
    [QualifyingIncrementalSales] MONEY          NULL,
    [QualifyingCashback]         MONEY          NULL,
    [QualifyingOverride]         MONEY          NULL,
    [TotalSpenders]              INT            NULL,
    [QualifyingSpenders]         INT            NULL,
    [LengthWeeks]                INT            NULL,
    [ForecastSubmissionDate]     DATETIME       NULL,
    [Status_StartDate]           DATE           NOT NULL,
    [Status_EndDate]             DATE           NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

