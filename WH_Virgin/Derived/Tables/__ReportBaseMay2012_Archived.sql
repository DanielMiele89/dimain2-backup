CREATE TABLE [Derived].[__ReportBaseMay2012_Archived] (
    [FanID]           INT          NOT NULL,
    [CompositeID]     BIGINT       NOT NULL,
    [SourceUID]       VARCHAR (20) NULL,
    [IsControl]       BIT          NULL,
    [AnalysisGroupL1] VARCHAR (4)  NULL,
    [AnalysisGroupL2] VARCHAR (4)  NULL,
    [ReportFromDate]  DATE         NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

