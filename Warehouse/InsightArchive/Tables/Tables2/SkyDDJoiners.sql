CREATE TABLE [InsightArchive].[SkyDDJoiners] (
    [BankAccountID] INT          NOT NULL,
    [BrandName]     VARCHAR (50) NOT NULL,
    [SectorName]    VARCHAR (50) NULL,
    [FirstTran]     DATE         NULL,
    [Spend]         MONEY        NULL
);


GO
CREATE CLUSTERED INDEX [ix_ComboID]
    ON [InsightArchive].[SkyDDJoiners]([BankAccountID] ASC);

