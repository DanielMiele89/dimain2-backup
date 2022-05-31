CREATE TABLE [SamW].[DD_TopLine] (
    [TransactionDate] DATETIME     NULL,
    [Spend]           MONEY        NULL,
    [Transactions]    INT          NULL,
    [Customers]       INT          NULL,
    [BrandName]       VARCHAR (50) NOT NULL,
    [SectorName]      VARCHAR (50) NULL
);


GO
CREATE CLUSTERED INDEX [ix_ComboID]
    ON [SamW].[DD_TopLine]([TransactionDate] ASC);

