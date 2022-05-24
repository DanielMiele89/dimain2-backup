CREATE TABLE [MIDI].[ConsumerTransactionHolding] (
    [TransactionID]          VARCHAR (100) NOT NULL,
    [FileID]                 INT           NOT NULL,
    [RowNum]                 VARCHAR (100) NOT NULL,
    [ConsumerCombinationID]  INT           NOT NULL,
    [SecondaryCombinationID] INT           NULL,
    [BankID]                 SMALLINT      NULL,
    [LocationID]             INT           NOT NULL,
    [CardholderPresentData]  TINYINT       NULL,
    [TranDate]               DATETIME2 (0) NOT NULL,
    [CINID]                  BIGINT        NOT NULL,
    [Amount]                 MONEY         NOT NULL,
    [IsRefund]               BIT           NOT NULL,
    [IsOnline]               BIT           NOT NULL,
    [InputModeID]            TINYINT       NULL,
    [PaymentTypeID]          TINYINT       CONSTRAINT [DF_midi_ConsumerTransactionHolding_PaymentTypeID] DEFAULT ((2)) NOT NULL,
    CONSTRAINT [PK_midi_ConsumerTransactionHolding] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_midi_ConsumerTransactionHolding_Combination] FOREIGN KEY ([ConsumerCombinationID]) REFERENCES [Trans].[ConsumerCombination] ([ConsumerCombinationID])
);

