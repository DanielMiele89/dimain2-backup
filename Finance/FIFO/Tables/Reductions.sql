CREATE TABLE [FIFO].[Reductions] (
    [ReductionSourceID]       INT            NOT NULL,
    [CustomerID]              INT            NOT NULL,
    [PublisherID]             INT            NOT NULL,
    [Reduction]               DECIMAL (9, 2) NOT NULL,
    [ReductionDateTime]       DATETIME2 (7)  NOT NULL,
    [isBreakage]              BIT            NOT NULL,
    [CustomerReductionID]     INT            NULL,
    [CumulativeReductionFrom] DECIMAL (9, 2) NULL,
    [CumulativeReductionTo]   DECIMAL (9, 2) NULL,
    [PreviousCustomerID]      INT            NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [FIFO].[Reductions]([CustomerID] ASC, [ReductionDateTime] ASC, [ReductionSourceID] ASC) WITH (FILLFACTOR = 90);

