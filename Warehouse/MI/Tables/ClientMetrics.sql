CREATE TABLE [MI].[ClientMetrics] (
    [ID]       INT           IDENTITY (1, 1) NOT NULL,
    [Retailer] NVARCHAR (40) NULL,
    [Date]     DATE          NULL,
    [Value]    MONEY         NULL,
    [Club]     NVARCHAR (30) NULL,
    [Forecast] BIT           NULL
);

