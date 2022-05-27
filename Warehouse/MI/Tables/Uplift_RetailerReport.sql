CREATE TABLE [MI].[Uplift_RetailerReport] (
    [ID]           INT              IDENTITY (1, 1) NOT NULL,
    [UpliftRowID]  INT              NOT NULL,
    [ResultsRowID] INT              NOT NULL,
    [Weight]       DECIMAL (38, 37) NULL,
    [MetricID]     TINYINT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

