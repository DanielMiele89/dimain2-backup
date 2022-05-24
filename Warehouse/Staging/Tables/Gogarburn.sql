CREATE TABLE [Staging].[Gogarburn] (
    [FanID]             INT           NOT NULL,
    [Surname]           VARCHAR (50)  NULL,
    [MaskedCardNumber]  VARCHAR (19)  NULL,
    [TranDate]          DATE          NULL,
    [TransactionAmount] SMALLMONEY    NULL,
    [MerchantID]        NVARCHAR (15) NULL,
    [Narrative]         NVARCHAR (25) NULL,
    [TotalCashbackDue]  MONEY         NULL,
    [AlreadyAwarded]    VARCHAR (200) NULL,
    [AlreadyEarned]     SMALLMONEY    NULL,
    [RemainingCashback] MONEY         NULL,
    [FileID]            INT           NOT NULL,
    [RowNum]            INT           NOT NULL,
    [DataDate]          DATE          NULL
);

