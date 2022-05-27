CREATE TABLE [AWSFile].[ConsumerTransactionForFile] (
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
    [PaymentTypeID]         TINYINT NOT NULL,
    CONSTRAINT [PK_AWSFile_ConsumerTransactionForFile] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);




GO
GRANT SELECT
    ON OBJECT::[AWSFile].[ConsumerTransactionForFile] TO [dops_066]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[AWSFile].[ConsumerTransactionForFile] TO [gas]
    AS [dbo];

