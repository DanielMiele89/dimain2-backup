CREATE TABLE [InsightArchive].[NEW_DAILY_TRANSACTIONS_CUSTOM_SECTORS_NEW] (
    [Custom Sector]      VARCHAR (23) NOT NULL,
    [TranDate]           DATE         NULL,
    [IsOnline]           BIT          NOT NULL,
    [TOTAL_SALES]        MONEY        NULL,
    [TRANSACTIONS]       INT          NULL,
    [EQUIV_TRANDATE]     DATE         NULL,
    [EQUIV_TOTAL_SALES]  MONEY        NULL,
    [EQUIV_TRANSACTIONS] INT          NULL
);

