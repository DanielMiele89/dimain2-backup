CREATE TABLE [InsightArchive].[SkyDDLeavers] (
    [BankAccountID] INT          NOT NULL,
    [BrandName]     VARCHAR (50) NOT NULL,
    [SectorName]    VARCHAR (50) NULL,
    [LastTran]      DATE         NULL,
    [Spend]         MONEY        NULL
);


GO
CREATE CLUSTERED INDEX [ix_ComboID]
    ON [InsightArchive].[SkyDDLeavers]([BankAccountID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

