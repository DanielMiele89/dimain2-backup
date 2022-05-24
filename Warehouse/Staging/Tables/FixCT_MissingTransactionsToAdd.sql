CREATE TABLE [Staging].[FixCT_MissingTransactionsToAdd] (
    [BatchID]               INT     NOT NULL,
    [FileID]                INT     NOT NULL,
    [RowNum]                INT     NOT NULL,
    [ConsumerCombinationID] INT     NOT NULL,
    [CardholderPresentData] TINYINT NOT NULL,
    [TranDate]              DATE    NOT NULL,
    [CINID]                 INT     NOT NULL,
    [Amount]                MONEY   NOT NULL,
    [IsOnline]              BIT     NOT NULL,
    [PaymentTypeID]         INT     NOT NULL
);

