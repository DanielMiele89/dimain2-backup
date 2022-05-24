﻿CREATE TABLE [Relational].[BookingCal_ForecastWave] (
    [ID]                        INT            IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef]         VARCHAR (40)   NOT NULL,
    [Campaign_StartDate]        DATE           NULL,
    [Campaign_EndDate]          DATE           NULL,
    [TargetedVolume]            INT            NULL,
    [ControlVolume]             INT            NULL,
    [CustomerBaseType]          INT            NULL,
    [Base]                      INT            NULL,
    [AvgOfferRate]              NUMERIC (7, 4) NULL,
    [TotalSales]                MONEY          NULL,
    [QualifyingSales]           MONEY          NULL,
    [TotalIncrementalSales]     MONEY          NULL,
    [WeeklySpenders]            INT            NULL,
    [TotalSpenders]             INT            NULL,
    [QualifyingSpenders]        INT            NULL,
    [TotalIncrementalSpednders] INT            NULL,
    [TotalCashback]             MONEY          NULL,
    [TotalOverride]             MONEY          NULL,
    [QualifyingCashback]        MONEY          NULL,
    [QualifyingOverride]        MONEY          NULL,
    [LengthWeeks]               INT            NULL,
    [ForecastSubmissionDate]    DATETIME       NULL,
    [RetailerType]              VARCHAR (40)   NULL,
    [Status_StartDate]          DATE           NOT NULL,
    [Status_EndDate]            DATE           NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

