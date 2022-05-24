CREATE TABLE [MIDI].[ConsumerTransaction_ExportToAWS_20220427] (
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
    [PaymentTypeID]          TINYINT       CONSTRAINT [DF_Trans_ConsumerTransaction_ExportToAWS_PaymentTypeID_20220427] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_ConsumerTrans_20220427] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC, [TranDate] ASC) WITH (FILLFACTOR = 95),
    CONSTRAINT [FK_Trans_ConsumerTransaction_ExportToAWS_Combination_20220427] FOREIGN KEY ([ConsumerCombinationID]) REFERENCES [Trans].[ConsumerCombination_20220427] ([ConsumerCombinationID])
);




GO
GRANT SELECT
    ON OBJECT::[MIDI].[ConsumerTransaction_ExportToAWS_20220427] TO [visa_etl_user]
    AS [New_DataOps];


GO
GRANT DELETE
    ON OBJECT::[MIDI].[ConsumerTransaction_ExportToAWS_20220427] TO [visa_etl_user]
    AS [New_DataOps];


GO
GRANT ALTER
    ON OBJECT::[MIDI].[ConsumerTransaction_ExportToAWS_20220427] TO [visa_etl_user]
    AS [New_DataOps];

