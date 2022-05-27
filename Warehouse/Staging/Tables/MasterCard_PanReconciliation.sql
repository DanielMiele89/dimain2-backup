CREATE TABLE [Staging].[MasterCard_PanReconciliation] (
    [PaymentCardID]      INT     NULL,
    [PanID]              INT     NULL,
    [IsActiveReward]     TINYINT NULL,
    [IsActiveMasterCard] TINYINT NULL
);


GO
CREATE CLUSTERED INDEX [cix_MCRecon]
    ON [Staging].[MasterCard_PanReconciliation]([PaymentCardID] ASC);


GO
CREATE NONCLUSTERED INDEX [ix_MCRecon_PanID]
    ON [Staging].[MasterCard_PanReconciliation]([PanID] ASC);

