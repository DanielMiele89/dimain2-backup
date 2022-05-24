CREATE TABLE [InsightArchive].[TOP_5_GROCERS] (
    [BrandName]          VARCHAR (50) NOT NULL,
    [TranDate]           DATE         NULL,
    [IsOnline]           BIT          NOT NULL,
    [TOTAL_SALES]        MONEY        NULL,
    [TRANSACTIONS]       INT          NULL,
    [EQUIV_TRANDATE]     DATE         NULL,
    [EQUIV_TOTAL_SALES]  MONEY        NULL,
    [EQUIV_TRANSACTIONS] INT          NULL
);

