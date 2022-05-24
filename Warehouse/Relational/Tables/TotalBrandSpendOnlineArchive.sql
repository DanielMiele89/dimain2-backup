CREATE TABLE [Relational].[TotalBrandSpendOnlineArchive] (
    [SpendArchiveID] INT      IDENTITY (1, 1) NOT NULL,
    [StartDate]      DATE     NOT NULL,
    [EndDate]        DATE     NOT NULL,
    [BrandID]        SMALLINT NOT NULL,
    [Amount]         MONEY    NOT NULL,
    [CustomerCount]  INT      NOT NULL,
    [TransCount]     INT      NOT NULL,
    CONSTRAINT [PK_Relational_TotalBrandSpendOnlineArchive] PRIMARY KEY CLUSTERED ([SpendArchiveID] ASC)
);

