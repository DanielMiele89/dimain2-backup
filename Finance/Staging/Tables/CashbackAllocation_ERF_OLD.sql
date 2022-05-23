CREATE TABLE [Staging].[CashbackAllocation_ERF_OLD] (
    [ID]               INT      NULL,
    [FanID]            INT      NULL,
    [CashbackSourceID] INT      NULL,
    [AllocationDate]   DATE     NULL,
    [AllocationAmount] MONEY    NULL,
    [PaymentMethodID]  SMALLINT NULL,
    [AwardID]          INT      NULL,
    [ReductionID]      INT      NULL,
    [BankID]           TINYINT  NULL,
    [IsRedemption]     BIT      NULL,
    [RBSFunded]        BIT      NULL
);


GO
CREATE NONCLUSTERED INDEX [NIX]
    ON [Staging].[CashbackAllocation_ERF_OLD]([ReductionID] ASC)
    INCLUDE([AwardID], [ID], [FanID], [AllocationAmount], [CashbackSourceID]);

