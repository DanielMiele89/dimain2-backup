CREATE TABLE [FIFO].[ReductionAllocations] (
    [AllocationID]             BIGINT         IDENTITY (1, 1) NOT NULL,
    [CustomerID]               INT            NOT NULL,
    [PublisherID]              SMALLINT       NOT NULL,
    [isBreakage]               BIT            NOT NULL,
    [ReductionDate]            DATE           NOT NULL,
    [Reduction]                DECIMAL (9, 2) NOT NULL,
    [ReductionRemaining]       DECIMAL (9, 2) NOT NULL,
    [EarningDate]              DATE           NULL,
    [Earning]                  DECIMAL (9, 2) NULL,
    [EarningAllocated]         DECIMAL (9, 2) NULL,
    [EarningRemaining]         DECIMAL (9, 2) NULL,
    [EarningSourceID]          INT            NULL,
    [PaymentCardID]            INT            NULL,
    [PaymentMethodID]          SMALLINT       NULL,
    [TranDate]                 DATE           NULL,
    [ReductionSourceID]        INT            NOT NULL,
    [TransactionID]            INT            NULL,
    [CustomerEarningOrdinal]   INT            NOT NULL,
    [CustomerReductionOrdinal] INT            NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [UCIX_Ordinal]
    ON [FIFO].[ReductionAllocations]([CustomerID] ASC, [CustomerEarningOrdinal] ASC, [CustomerReductionOrdinal] ASC) WITH (FILLFACTOR = 90);

