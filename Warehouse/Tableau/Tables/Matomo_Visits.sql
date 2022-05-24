CREATE TABLE [Tableau].[Matomo_Visits] (
    [Matomo_VisitsID]     INT             IDENTITY (1, 1) NOT NULL,
    [FanID]               INT             NOT NULL,
    [ReferrerURL]         NVARCHAR (2100) NULL,
    [FirstActionDateTime] DATETIME2 (7)   NOT NULL,
    [VisitDuration]       INT             NOT NULL,
    [DeviceBrand]         NVARCHAR (50)   NOT NULL,
    [DeviceModel]         NVARCHAR (50)   NOT NULL,
    [DeviceType]          NVARCHAR (50)   NOT NULL,
    [LoadDate]            DATETIME2 (7)   NOT NULL,
    CONSTRAINT [PK_Matomo_Visits] PRIMARY KEY CLUSTERED ([Matomo_VisitsID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [idx_Matomo_Visits]
    ON [Tableau].[Matomo_Visits]([FirstActionDateTime] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

