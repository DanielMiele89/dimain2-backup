CREATE TABLE [Staging].[CycleReport_RetailerAnalysisDates] (
    [RetailerAnalysisID] INT  IDENTITY (1, 1) NOT NULL,
    [RetailerID]         INT  NOT NULL,
    [StartDate]          DATE NOT NULL,
    [EndDate]            DATE NOT NULL,
    [IsBespoke]          BIT  NOT NULL,
    [IsCalculated]       BIT  NOT NULL,
    CONSTRAINT [PK_CycleReport_RetailerAnalysisDates] PRIMARY KEY CLUSTERED ([RetailerAnalysisID] ASC),
    CONSTRAINT [Constraint_CycleReport_RetailerAnalysisDates] UNIQUE NONCLUSTERED ([RetailerID] ASC, [StartDate] ASC, [EndDate] ASC)
);

