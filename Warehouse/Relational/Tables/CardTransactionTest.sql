CREATE TABLE [Relational].[CardTransactionTest] (
    [FileID]                INT           NOT NULL,
    [RowNum]                INT           NOT NULL,
    [BrandMIDID]            INT           NOT NULL,
    [BankID]                TINYINT       NULL,
    [TerminalID]            VARCHAR (8)   NULL,
    [MID]                   VARCHAR (50)  NOT NULL,
    [Narrative]             VARCHAR (50)  NOT NULL,
    [LocationAddress]       VARCHAR (50)  NOT NULL,
    [LocationCountry]       VARCHAR (3)   NOT NULL,
    [MCC]                   VARCHAR (4)   NOT NULL,
    [CardholderPresentData] CHAR (1)      NOT NULL,
    [TranDate]              SMALLDATETIME NULL,
    [InDate]                SMALLDATETIME NULL,
    [CINID]                 INT           NULL,
    [Amount]                MONEY         NOT NULL,
    CONSTRAINT [PK_CardTransactionTest] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);




GO
GRANT SELECT
    ON OBJECT::[Relational].[CardTransactionTest] TO [gas]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Relational].[CardTransactionTest] TO [gas]
    AS [dbo];

