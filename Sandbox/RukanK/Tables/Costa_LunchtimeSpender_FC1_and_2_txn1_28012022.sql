CREATE TABLE [RukanK].[Costa_LunchtimeSpender_FC1_and_2_txn1_28012022] (
    [CINID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_CINID]
    ON [RukanK].[Costa_LunchtimeSpender_FC1_and_2_txn1_28012022]([CINID] ASC) WITH (FILLFACTOR = 90);

