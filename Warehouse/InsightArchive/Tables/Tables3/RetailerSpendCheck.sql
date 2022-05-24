CREATE TABLE [InsightArchive].[RetailerSpendCheck] (
    [PartnerID]    INT   NOT NULL,
    [TranCount]    INT   NOT NULL,
    [SpenderCount] INT   NOT NULL,
    [Sales]        MONEY NOT NULL,
    [commission]   MONEY NOT NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC)
);

