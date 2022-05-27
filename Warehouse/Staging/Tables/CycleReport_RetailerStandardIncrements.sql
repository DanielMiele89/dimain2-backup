CREATE TABLE [Staging].[CycleReport_RetailerStandardIncrements] (
    [RetailerID]                 INT          NOT NULL,
    [StandardReportingIncrement] VARCHAR (50) NOT NULL,
    [StandardIncrementAmount]    INT          NOT NULL,
    CONSTRAINT [PK_CycleReport_RetailerStandardIncrements] PRIMARY KEY CLUSTERED ([RetailerID] ASC)
);

