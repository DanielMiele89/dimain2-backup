CREATE TABLE [InsightArchive].[DDLeavers] (
    [BankAccountID] INT          NOT NULL,
    [BrandName]     VARCHAR (50) NOT NULL,
    [SectorName]    VARCHAR (50) NULL,
    [LastTran]      DATE         NULL,
    [Spend]         MONEY        NULL
);


GO
CREATE CLUSTERED INDEX [ix_ComboID]
    ON [InsightArchive].[DDLeavers]([BankAccountID] ASC);

