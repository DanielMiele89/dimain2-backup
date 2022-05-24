CREATE TABLE [Staging].[CardTransactionIncorrectMID] (
    [FileID]                INT          NOT NULL,
    [RowNum]                INT          NOT NULL,
    [BankID]                VARCHAR (4)  NULL,
    [TerminalID]            VARCHAR (8)  NULL,
    [MID]                   VARCHAR (50) NOT NULL,
    [Narrative]             VARCHAR (22) NOT NULL,
    [LocationAddress]       VARCHAR (18) NOT NULL,
    [LocationCountry]       VARCHAR (3)  NOT NULL,
    [MCC]                   VARCHAR (4)  NOT NULL,
    [CardholderPresentData] CHAR (1)     NOT NULL,
    [TranDate]              VARCHAR (10) NULL,
    [PaymentCardID]         INT          NULL,
    [Amount]                MONEY        NOT NULL,
    CONSTRAINT [PK_CardTransactionIncorrectMID] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);

