CREATE TABLE [SamW].[DDJoinersSpend] (
    [BrandName]  VARCHAR (50) NOT NULL,
    [SectorName] VARCHAR (50) NULL,
    [TranDate]   DATE         NULL,
    [Spend]      MONEY        NULL
);


GO
CREATE CLUSTERED INDEX [ix_ComboID]
    ON [SamW].[DDJoinersSpend]([BrandName] ASC);

