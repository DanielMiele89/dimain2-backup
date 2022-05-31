CREATE TABLE [SamW].[JoinersLeaversSpend] (
    [BrandName]    VARCHAR (50) NOT NULL,
    [SectorName]   VARCHAR (50) NULL,
    [FirstTran]    DATETIME     NULL,
    [LastTran]     DATETIME     NULL,
    [LeaversSpend] MONEY        NULL,
    [JoinersSpend] MONEY        NULL
);


GO
CREATE CLUSTERED INDEX [ix_ComboID]
    ON [SamW].[JoinersLeaversSpend]([BrandName] ASC);

