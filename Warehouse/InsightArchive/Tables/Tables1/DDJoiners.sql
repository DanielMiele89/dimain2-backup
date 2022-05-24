CREATE TABLE [InsightArchive].[DDJoiners] (
    [BankAccountID] INT          NOT NULL,
    [BrandName]     VARCHAR (50) NOT NULL,
    [SectorName]    VARCHAR (50) NULL,
    [FirstTran]     DATE         NULL,
    [Spend]         MONEY        NULL
);


GO
CREATE CLUSTERED INDEX [ix_ComboID]
    ON [InsightArchive].[DDJoiners]([BankAccountID] ASC);

