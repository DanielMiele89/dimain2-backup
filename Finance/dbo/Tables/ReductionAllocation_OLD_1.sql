CREATE TABLE [dbo].[ReductionAllocation_OLD] (
    [AllocationID]             BIGINT  IDENTITY (1, 1) NOT NULL,
    [CustomerID]               INT     NOT NULL,
    [EarningID]                INT     NULL,
    [EarningTypeID]            TINYINT NULL,
    [ReductionID]              INT     NOT NULL,
    [ReductionTypeID]          TINYINT NOT NULL,
    [PartnerID]                INT     NOT NULL,
    [EarningSourceID]          INT     NULL,
    [EarningDate]              DATE    NULL,
    [Earning]                  MONEY   NULL,
    [ReductionDate]            DATE    NOT NULL,
    [Reduction]                MONEY   NOT NULL,
    [AllocatedEarning]         MONEY   NULL,
    [RemainingEarning]         MONEY   NULL,
    [RemainingReduction]       MONEY   NOT NULL,
    [isFullAllocatedReduction] BIT     NULL,
    [isFullAllocatedEarning]   BIT     NOT NULL,
    [AllocationOrder]          INT     NOT NULL,
    CONSTRAINT [PK_ReductionAllocation_OLD] PRIMARY KEY CLUSTERED ([AllocationID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_ReductionAllocation_CustomerID_OLD] FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customer_OLD] ([CustomerID]),
    CONSTRAINT [FK_ReductionAllocation_EarningSourceID_OLD] FOREIGN KEY ([EarningSourceID]) REFERENCES [dbo].[EarningSource_OLD] ([EarningSourceID]),
    CONSTRAINT [FK_ReductionAllocation_EarningTypeID_OLD] FOREIGN KEY ([EarningTypeID]) REFERENCES [dbo].[EarningType_OLD] ([EarningTypeID]),
    CONSTRAINT [FK_ReductionAllocation_PartnerID_OLD] FOREIGN KEY ([PartnerID]) REFERENCES [dbo].[Partner_OLD] ([PartnerID]),
    CONSTRAINT [FK_ReductionAllocation_ReductionTypeID_OLD] FOREIGN KEY ([ReductionTypeID]) REFERENCES [dbo].[ReductionType_OLD] ([ReductionTypeID])
);


GO
ALTER TABLE [dbo].[ReductionAllocation_OLD] NOCHECK CONSTRAINT [FK_ReductionAllocation_CustomerID_OLD];


GO
ALTER TABLE [dbo].[ReductionAllocation_OLD] NOCHECK CONSTRAINT [FK_ReductionAllocation_EarningSourceID_OLD];


GO
ALTER TABLE [dbo].[ReductionAllocation_OLD] NOCHECK CONSTRAINT [FK_ReductionAllocation_EarningTypeID_OLD];


GO
ALTER TABLE [dbo].[ReductionAllocation_OLD] NOCHECK CONSTRAINT [FK_ReductionAllocation_ReductionTypeID_OLD];


GO
CREATE NONCLUSTERED INDEX [nix_earningidtypeid]
    ON [dbo].[ReductionAllocation_OLD]([EarningTypeID] ASC, [EarningID] ASC);


GO
ALTER INDEX [nix_earningidtypeid]
    ON [dbo].[ReductionAllocation_OLD] DISABLE;


GO
CREATE NONCLUSTERED INDEX [NIX_isFullAllocatedEarning]
    ON [dbo].[ReductionAllocation_OLD]([isFullAllocatedEarning] ASC)
    INCLUDE([CustomerID], [ReductionID], [EarningID], [EarningTypeID], [ReductionTypeID]);


GO
ALTER INDEX [NIX_isFullAllocatedEarning]
    ON [dbo].[ReductionAllocation_OLD] DISABLE;


GO
CREATE NONCLUSTERED INDEX [NIX_REductionIDAllocationOrder]
    ON [dbo].[ReductionAllocation_OLD]([ReductionID] ASC, [AllocationOrder] ASC);


GO
ALTER INDEX [NIX_REductionIDAllocationOrder]
    ON [dbo].[ReductionAllocation_OLD] DISABLE;


GO
CREATE NONCLUSTERED INDEX [NIX_CustomerID]
    ON [dbo].[ReductionAllocation_OLD]([CustomerID] ASC)
    INCLUDE([EarningSourceID], [EarningID], [EarningTypeID], [AllocatedEarning], [ReductionID], [Reduction]);


GO
ALTER INDEX [NIX_CustomerID]
    ON [dbo].[ReductionAllocation_OLD] DISABLE;


GO
CREATE NONCLUSTERED INDEX [NIX_Temp]
    ON [dbo].[ReductionAllocation_OLD]([ReductionID] ASC, [EarningID] ASC)
    INCLUDE([CustomerID]);


GO
ALTER INDEX [NIX_Temp]
    ON [dbo].[ReductionAllocation_OLD] DISABLE;


GO
CREATE NONCLUSTERED INDEX [NIX_Breakage]
    ON [dbo].[ReductionAllocation_OLD]([EarningDate] ASC)
    INCLUDE([Earning], [AllocatedEarning], [isFullAllocatedEarning]);


GO
ALTER INDEX [NIX_Breakage]
    ON [dbo].[ReductionAllocation_OLD] DISABLE;


GO
CREATE NONCLUSTERED INDEX [NIX_CashbackStatus]
    ON [dbo].[ReductionAllocation_OLD]([EarningTypeID] ASC)
    INCLUDE([AllocationID], [EarningID]);


GO
CREATE NONCLUSTERED INDEX [NIX_CustOnly]
    ON [dbo].[ReductionAllocation_OLD]([CustomerID] ASC);

