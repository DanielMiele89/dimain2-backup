CREATE TABLE [AWSFile].[ConsumerTransaction_CreditCardForFile] (
    [FileID]                INT     NOT NULL,
    [RowNum]                INT     NOT NULL,
    [ConsumerCombinationID] INT     NOT NULL,
    [CardholderPresentData] TINYINT NOT NULL,
    [TranDate]              DATE    NOT NULL,
    [CINID]                 INT     NOT NULL,
    [Amount]                MONEY   NOT NULL,
    [IsOnline]              BIT     NOT NULL,
    [LocationID]            INT     NOT NULL,
    [FanID]                 INT     NULL,
    CONSTRAINT [PK_AWSFile_ConsumerTransaction_CreditCardForFile] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);

