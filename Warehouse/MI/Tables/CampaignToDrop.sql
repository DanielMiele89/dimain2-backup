CREATE TABLE [MI].[CampaignToDrop] (
    [ID]                           INT           IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef]            VARCHAR (40)  NOT NULL,
    [StartDate]                    DATE          NOT NULL,
    [MaxEndDate]                   DATE          NULL,
    [InternalControlGroup]         VARCHAR (100) NOT NULL,
    [ExternalControlGroup]         VARCHAR (100) NOT NULL,
    [Cardholders]                  BIGINT        NULL,
    [InternalControlGroupSize]     BIGINT        NULL,
    [ExternalControlGroupSize]     BIGINT        NULL,
    [Sales]                        MONEY         NULL,
    [Commission]                   MONEY         NULL,
    [InternalSalesUplift]          REAL          NULL,
    [ExternalSalesUplift]          REAL          NULL,
    [InternalSignificantUpliftSPC] VARCHAR (40)  NULL,
    [ExternalSignificantUpliftSPC] VARCHAR (40)  NULL,
    [SalesCheck]                   VARCHAR (40)  NOT NULL,
    [UpliftCheck]                  VARCHAR (40)  NOT NULL,
    [AdjFactorCapCheck]            VARCHAR (10)  NOT NULL,
    [VolumeForecastCheck]          VARCHAR (40)  NOT NULL,
    [SPCForecastCheck]             VARCHAR (40)  NOT NULL,
    [InsertTime]                   DATETIME      NULL
);

