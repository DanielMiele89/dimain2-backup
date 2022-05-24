CREATE TABLE [Staging].[TTCW.VM.REWARDS.TRX.202105132143] (
    [BankID]            INT           NOT NULL,
    [CardID]            NVARCHAR (50) NOT NULL,
    [Reversal]          NVARCHAR (50) NOT NULL,
    [MerchantID]        NVARCHAR (50) NOT NULL,
    [Country]           NVARCHAR (50) NOT NULL,
    [Narrative]         NVARCHAR (50) NOT NULL,
    [CardHolder]        NVARCHAR (50) NOT NULL,
    [MCC]               NVARCHAR (50) NOT NULL,
    [TransactionDate]   DATETIME2 (7) NOT NULL,
    [TransactionTime]   DATETIME2 (7) NOT NULL,
    [TransactionAmount] FLOAT (53)    NOT NULL,
    [CurrencyCode]      NVARCHAR (50) NOT NULL,
    [PostStatus]        NVARCHAR (50) NOT NULL,
    [CardInputMode]     NVARCHAR (50) NOT NULL,
    [column_15]         NVARCHAR (1)  NULL
);

