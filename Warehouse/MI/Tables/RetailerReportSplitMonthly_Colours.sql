CREATE TABLE [MI].[RetailerReportSplitMonthly_Colours] (
    [id]                    INT         IDENTITY (1, 1) NOT NULL,
    [Split_Use_For_Report]  INT         NOT NULL,
    [Status_Use_For_Report] INT         NOT NULL,
    [Colour]                VARCHAR (8) NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

