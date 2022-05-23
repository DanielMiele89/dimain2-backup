CREATE TABLE [dbo].[FIFO_MovedEarnings_OLD] (
    [AllocationID]             BIGINT   NULL,
    [CustomerID]               INT      NOT NULL,
    [EarningID]                INT      NULL,
    [EarningTypeID]            TINYINT  NULL,
    [ReductionID]              INT      NOT NULL,
    [ReductionTypeID]          TINYINT  NOT NULL,
    [PartnerID]                SMALLINT NOT NULL,
    [EarningSourceID]          INT      NULL,
    [EarningDate]              DATE     NULL,
    [Earning]                  MONEY    NULL,
    [ReductionDate]            DATE     NOT NULL,
    [Reduction]                MONEY    NOT NULL,
    [AllocatedEarning]         MONEY    NULL,
    [RemainingEarning]         MONEY    NULL,
    [RemainingReduction]       MONEY    NOT NULL,
    [isFullAllocatedReduction] BIT      NULL,
    [isFullAllocatedEarning]   BIT      NOT NULL,
    [AllocationOrder]          INT      NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [NIX]
    ON [dbo].[FIFO_MovedEarnings_OLD]([CustomerID] ASC);

