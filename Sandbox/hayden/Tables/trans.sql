CREATE TABLE [hayden].[trans] (
    [FileID]                INT     NOT NULL,
    [RowNum]                INT     NOT NULL,
    [ConsumerCombinationID] INT     NOT NULL,
    [CardholderPresentData] TINYINT NOT NULL,
    [TranDate]              DATE    NULL,
    [CINID]                 INT     NOT NULL,
    [Amount]                MONEY   NOT NULL,
    [IsRefund]              BIT     NOT NULL,
    [IsOnline]              BIT     NOT NULL,
    [InputModeID]           TINYINT NULL,
    [PaymentTypeID]         TINYINT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [hayden].[trans]([FileID] ASC, [RowNum] ASC);


GO
CREATE NONCLUSTERED INDEX [NIX]
    ON [hayden].[trans]([TranDate] ASC);

