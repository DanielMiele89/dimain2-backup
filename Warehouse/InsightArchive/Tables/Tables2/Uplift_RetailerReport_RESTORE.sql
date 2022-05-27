CREATE TABLE [InsightArchive].[Uplift_RetailerReport_RESTORE] (
    [ID]           INT              NOT NULL,
    [UpliftRowID]  INT              NOT NULL,
    [ResultsRowID] INT              NOT NULL,
    [Weight]       DECIMAL (38, 37) NULL,
    [MetricID]     TINYINT          NOT NULL
);

