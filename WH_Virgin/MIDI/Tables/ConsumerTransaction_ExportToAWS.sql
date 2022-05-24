CREATE TABLE [MIDI].[ConsumerTransaction_ExportToAWS] (
    [FileID]                 INT           NOT NULL,
    [RowNum]                 INT           NOT NULL,
    [ConsumerCombinationID]  INT           NOT NULL,
    [SecondaryCombinationID] INT           NULL,
    [BankID]                 SMALLINT      NULL,
    [CardholderPresentData]  TINYINT       NOT NULL,
    [TranDate]               DATETIME2 (0) NOT NULL,
    [CINID]                  INT           NOT NULL,
    [Amount]                 MONEY         NOT NULL,
    [IsRefund]               BIT           NOT NULL,
    [IsOnline]               BIT           NOT NULL,
    [InputModeID]            TINYINT       NOT NULL,
    [PaymentTypeID]          TINYINT       CONSTRAINT [DF_Trans_ConsumerTransaction_ExportToAWS_PaymentTypeID] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_ConsumerTrans] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC, [TranDate] ASC) WITH (FILLFACTOR = 95),
    CONSTRAINT [FK_Trans_ConsumerTransaction_ExportToAWS_Combination] FOREIGN KEY ([ConsumerCombinationID]) REFERENCES [Trans].[ConsumerCombination] ([ConsumerCombinationID])
);




GO
GRANT SELECT
    ON OBJECT::[MIDI].[ConsumerTransaction_ExportToAWS] TO [virgin_etl_user]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[MIDI].[ConsumerTransaction_ExportToAWS] TO [virgin_etl_user]
    AS [dbo];


GO
GRANT ALTER
    ON OBJECT::[MIDI].[ConsumerTransaction_ExportToAWS] TO [virgin_etl_user]
    AS [dbo];

