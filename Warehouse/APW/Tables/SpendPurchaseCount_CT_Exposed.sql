CREATE TABLE [APW].[SpendPurchaseCount_CT_Exposed] (
    [CINID]                 INT    NOT NULL,
    [ConsumerCombinationID] BIGINT NOT NULL,
    [TranCount]             BIGINT NULL,
    [Spend]                 MONEY  NULL
);


GO
CREATE CLUSTERED INDEX [CIX_CINCC]
    ON [APW].[SpendPurchaseCount_CT_Exposed]([CINID] ASC, [ConsumerCombinationID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = ROW);

