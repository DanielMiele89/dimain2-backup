CREATE TABLE [Staging].[R_0108_MB_Data] (
    [StartDate]           DATE            NOT NULL,
    [EndDate]             DATE            NOT NULL,
    [PartnerID]           SMALLINT        NOT NULL,
    [PartnerName]         VARCHAR (100)   NOT NULL,
    [MerchantID]          VARCHAR (25)    NOT NULL,
    [BUN]                 VARCHAR (25)    NULL,
    [BlendedCashbackRate] NUMERIC (32, 8) NULL,
    [Transactions]        INT             NULL,
    [TransactionAmount]   FLOAT (53)      NULL,
    [TotalCashbackEarned] FLOAT (53)      NULL,
    [TotalCost]           FLOAT (53)      NULL,
    [TotalOverride]       FLOAT (53)      NULL,
    [VAT]                 FLOAT (53)      NULL
);

