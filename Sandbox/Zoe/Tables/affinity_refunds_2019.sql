CREATE TABLE [Zoe].[affinity_refunds_2019] (
    [FileID]                 INT     NOT NULL,
    [RowNum]                 INT     NOT NULL,
    [ConsumerCombinationID]  INT     NOT NULL,
    [SecondaryCombinationID] INT     NULL,
    [BankID]                 TINYINT NOT NULL,
    [LocationID]             INT     NOT NULL,
    [CardholderPresentData]  TINYINT NOT NULL,
    [TranDate]               DATE    NOT NULL,
    [CINID]                  INT     NOT NULL,
    [Amount]                 MONEY   NOT NULL,
    [IsRefund]               BIT     NOT NULL,
    [IsOnline]               BIT     NOT NULL,
    [InputModeID]            TINYINT NOT NULL,
    [PostStatusID]           TINYINT NOT NULL,
    [PaymentTypeID]          TINYINT NOT NULL
);

