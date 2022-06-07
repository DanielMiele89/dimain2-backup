CREATE TABLE [FIFO].[ReductionIntervals] (
    [CustomerID]              INT             NOT NULL,
    [CustomerReductionID]     INT             NOT NULL,
    [ReductionDate]           DATE            NULL,
    [ReductionSourceID]       INT             NOT NULL,
    [Reduction]               DECIMAL (9, 2)  NOT NULL,
    [CumulativeReductionFrom] DECIMAL (38, 2) NULL,
    [CumulativeReductionTo]   DECIMAL (38, 2) NULL,
    [MinCustomerEarningID]    INT             NULL,
    [MaxCustomerEarningID]    INT             NULL,
    [EndEarnings]             DECIMAL (9, 2)  NULL,
    [isCarried]               BIT             NULL,
    [isBreakage]              BIT             NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_Stuff]
    ON [FIFO].[ReductionIntervals]([CustomerID] ASC, [CustomerReductionID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE UNIQUE NONCLUSTERED INDEX [ix_Stuff]
    ON [FIFO].[ReductionIntervals]([CustomerID] ASC, [ReductionDate] ASC, [ReductionSourceID] ASC)
    INCLUDE([Reduction], [CumulativeReductionTo], [CumulativeReductionFrom], [MinCustomerEarningID], [MaxCustomerEarningID], [EndEarnings], [isCarried]) WITH (FILLFACTOR = 90);

