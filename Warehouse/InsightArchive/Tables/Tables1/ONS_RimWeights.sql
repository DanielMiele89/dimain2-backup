CREATE TABLE [InsightArchive].[ONS_RimWeights] (
    [ID]                 INT          IDENTITY (1, 1) NOT NULL,
    [Age]                VARCHAR (20) NULL,
    [Gender]             VARCHAR (20) NULL,
    [Region]             VARCHAR (50) NULL,
    [Population]         INT          NULL,
    [WeightedPopulation] FLOAT (53)   NULL,
    [PerCustomerWeight]  FLOAT (53)   NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

