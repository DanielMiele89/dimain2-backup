CREATE TABLE [dbo].[NobleRainbowTransactionPreliminary] (
    [FileID]                INT           NOT NULL,
    [RowNum]                INT           NOT NULL,
    [BankID]                VARCHAR (4)   NULL,
    [ClearStatus]           VARCHAR (3)   NULL,
    [MTI]                   VARCHAR (4)   NULL,
    [FunctionCode]          VARCHAR (4)   NULL,
    [ReversalInd]           CHAR (1)      NULL,
    [ProcessCode]           VARCHAR (9)   NULL,
    [OriginatorID]          VARCHAR (11)  NULL,
    [MerchantID]            NVARCHAR (50) NULL,
    [TerminalID]            VARCHAR (8)   NULL,
    [LocationName]          NVARCHAR (22) NULL,
    [LocationAddress]       NVARCHAR (18) NULL,
    [LocationCountry]       NVARCHAR (3)  NULL,
    [MCC]                   VARCHAR (4)   NULL,
    [CardholderPresentData] CHAR (1)      NULL,
    [TranDate]              VARCHAR (10)  NULL,
    [TranCurrencyCode]      VARCHAR (4)   NULL,
    [TranCurrencyAmt]       VARCHAR (13)  NULL,
    [RecnCurrencyCode]      VARCHAR (4)   NULL,
    [RecnCurrencyAmt]       VARCHAR (13)  NULL,
    [PWCBAmt]               VARCHAR (13)  NULL,
    [PostFPInd]             CHAR (1)      NULL,
    [PostStatus]            CHAR (1)      NULL,
    [Amount]                AS            ( -(CONVERT([money],[RecnCurrencyAmt],(0))-CONVERT([money],[PWCBAmt],(0)))),
    [PaymentCardID]         INT           NULL,
    [RetailOutletID]        INT           NULL,
    CONSTRAINT [PK_NobleRainbowTransactionPreliminary] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC) WITH (DATA_COMPRESSION = PAGE)
);


GO
GRANT INSERT
    ON OBJECT::[dbo].[NobleRainbowTransactionPreliminary] TO [crtimport]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[NobleRainbowTransactionPreliminary] TO [crtimport]
    AS [dbo];

