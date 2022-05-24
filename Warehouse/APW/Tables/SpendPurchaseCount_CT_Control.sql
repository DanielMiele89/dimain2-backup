CREATE TABLE [APW].[SpendPurchaseCount_CT_Control] (
    [CINID]                 INT    NOT NULL,
    [ConsumerCombinationID] BIGINT NOT NULL,
    [TranCount]             BIGINT NULL,
    [Spend]                 MONEY  NULL
);


GO
CREATE CLUSTERED INDEX [CIX_CINCC]
    ON [APW].[SpendPurchaseCount_CT_Control]([CINID] ASC, [ConsumerCombinationID] ASC) WITH (DATA_COMPRESSION = ROW);

