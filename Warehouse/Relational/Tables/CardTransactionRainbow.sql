CREATE TABLE [Relational].[CardTransactionRainbow] (
    [FileID]                INT           NOT NULL,
    [RowNum]                INT           NOT NULL,
    [BrandMIDID]            INT           NOT NULL,
    [BankID]                TINYINT       NOT NULL,
    [Narrative]             VARCHAR (50)  NOT NULL,
    [LocationAddress]       VARCHAR (50)  NOT NULL,
    [LocationCountry]       VARCHAR (3)   NOT NULL,
    [MCC]                   VARCHAR (4)   NOT NULL,
    [CardholderPresentData] CHAR (1)      NOT NULL,
    [TranDate]              SMALLDATETIME NULL,
    [InDate]                SMALLDATETIME NULL,
    [CINID]                 INT           NULL,
    [Amount]                MONEY         NOT NULL,
    CONSTRAINT [PK_CardTransactionRainbow] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[Relational].[CardTransactionRainbow] TO [gas]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Relational].[CardTransactionRainbow] TO [gas]
    AS [dbo];

