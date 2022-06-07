CREATE TABLE [FIFO].[Reductions_Breakage] (
    [ReductionSourceID] INT            NULL,
    [CustomerID]        INT            NULL,
    [PublisherID]       INT            NULL,
    [Reduction]         DECIMAL (9, 2) NULL,
    [ReductionDateTime] DATETIME2 (7)  NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [FIFO].[Reductions_Breakage]([ReductionSourceID] ASC) WITH (FILLFACTOR = 90);

