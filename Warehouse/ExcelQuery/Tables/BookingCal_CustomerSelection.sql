CREATE TABLE [ExcelQuery].[BookingCal_CustomerSelection] (
    [ClientServicesRef]        VARCHAR (40)  NOT NULL,
    [StartDate]                DATE          NULL,
    [EndDate]                  DATE          NULL,
    [SegmentID]                VARCHAR (6)   NULL,
    [Gender]                   CHAR (1)      NULL,
    [MinAge]                   INT           NULL,
    [MaxAge]                   INT           NULL,
    [DriveTimeBand]            VARCHAR (50)  NULL,
    [CAMEO_CODE_GRP]           VARCHAR (200) NULL,
    [SocialClass]              NVARCHAR (2)  NULL,
    [MinHeatMapScore]          INT           NULL,
    [MaxHeatMapScore]          INT           NULL,
    [BespokeTargeting]         INT           NULL,
    [QualifyingMids]           INT           NULL,
    [TargetedVolume]           INT           NULL,
    [ControlVolume]            INT           NULL,
    [TotalSpenders]            INT           NULL,
    [QualyfingSpenders]        INT           NULL,
    [TotalIncrementalSpenders] INT           NULL,
    [TotalSales]               MONEY         NULL,
    [QualifyingSales]          MONEY         NULL,
    [TotalIncrementalSales]    MONEY         NULL,
    [ForecastSubmissionDate]   DATETIME      NULL,
    [RetailerType]             VARCHAR (40)  NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_ClientServicesRef]
    ON [ExcelQuery].[BookingCal_CustomerSelection]([ClientServicesRef] ASC, [StartDate] ASC, [EndDate] ASC)
    INCLUDE([SegmentID]) WITH (FILLFACTOR = 95);


GO
CREATE CLUSTERED INDEX [cx_ClientServicesRef]
    ON [ExcelQuery].[BookingCal_CustomerSelection]([ClientServicesRef] ASC, [StartDate] ASC, [EndDate] ASC) WITH (FILLFACTOR = 90);

