CREATE TABLE [Relational].[ConsumerTransaction_CreditCardHolding] (
    [FileID]                 INT     NOT NULL,
    [RowNum]                 INT     NOT NULL,
    [ConsumerCombinationID]  INT     NOT NULL,
    [SecondaryCombinationID] INT     NULL,
    [CardholderPresentData]  TINYINT NOT NULL,
    [TranDate]               DATE    NOT NULL,
    [CINID]                  INT     NOT NULL,
    [Amount]                 MONEY   NOT NULL,
    [IsOnline]               BIT     NOT NULL,
    [LocationID]             INT     NOT NULL,
    [FanID]                  INT     NULL,
    CONSTRAINT [PK_ConsumerTransaction_CreditCardHolding] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC, [TranDate] ASC) WITH (FILLFACTOR = 85)
);

