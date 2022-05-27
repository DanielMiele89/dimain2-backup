CREATE TABLE [Staging].[RBSG_MonthlyReport_SpendEarnByPartner] (
    [PartnerName]         VARCHAR (100) NULL,
    [Primacy]             VARCHAR (1)   NULL,
    [UniqueCustomerCount] INT           NULL,
    [TransactionAmount]   MONEY         NULL,
    [TotalCashBack]       MONEY         NULL,
    [ClearedCashBack]     MONEY         NULL,
    [PendingCashback]     MONEY         NULL
);

