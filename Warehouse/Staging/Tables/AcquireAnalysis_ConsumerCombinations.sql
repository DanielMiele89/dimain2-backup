CREATE TABLE [Staging].[AcquireAnalysis_ConsumerCombinations] (
    [ConsumerCombinationID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_CC]
    ON [Staging].[AcquireAnalysis_ConsumerCombinations]([ConsumerCombinationID] ASC);

