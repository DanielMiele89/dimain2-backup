CREATE TABLE [dbo].[NobleTransactionPreliminary] (
    [RowNum]                INT           NULL,
    [BankID]                VARCHAR (4)   NULL,
    [ClearStatus]           VARCHAR (3)   NULL,
    [MTI]                   VARCHAR (4)   NULL,
    [FunctionCode]          VARCHAR (4)   NULL,
    [ReversalInd]           CHAR (1)      NULL,
    [ProcessCode]           VARCHAR (9)   NULL,
    [OriginatorID]          VARCHAR (11)  NULL,
    [TerminalID]            VARCHAR (8)   NULL,
    [LocationName]          NVARCHAR (22) NULL,
    [LocationAddress]       NVARCHAR (18) NULL,
    [LocationCountry]       NVARCHAR (3)  NULL,
    [MCC]                   VARCHAR (4)   NULL,
    [CardholderPresentData] CHAR (1)      NULL,
    [TranDate]              DATETIME      NULL,
    [TranCurrencyCode]      VARCHAR (4)   NULL,
    [TranCurrencyAmt]       VARCHAR (13)  NULL,
    [RecnCurrencyCode]      VARCHAR (4)   NULL,
    [RecnCurrencyAmt]       VARCHAR (13)  NULL,
    [PWCBAmt]               VARCHAR (13)  NULL,
    [PostFPInd]             CHAR (1)      NULL,
    [PostStatus]            CHAR (1)      NULL,
    [FileID]                INT           NULL,
    [PaymentCardID]         INT           NULL,
    [MerchantID]            NVARCHAR (50) NULL,
    [Amount]                AS            ( -(CONVERT([money],[RecnCurrencyAmt],(0))-CONVERT([money],[PWCBAmt],(0)))),
    [CompositeID]           BIGINT        NULL,
    [RetailOutletID]        INT           NULL
);


GO
CREATE CLUSTERED INDEX [ixc_NobleTransactionPreliminary]
    ON [dbo].[NobleTransactionPreliminary]([FileID] ASC, [RowNum] ASC);

