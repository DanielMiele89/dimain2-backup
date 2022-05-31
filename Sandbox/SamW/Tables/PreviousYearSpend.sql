CREATE TABLE [SamW].[PreviousYearSpend] (
    [TranDate]     DATE          NOT NULL,
    [BrandName]    VARCHAR (50)  NOT NULL,
    [SectorName]   VARCHAR (50)  NULL,
    [DAYOFWEEK]    NVARCHAR (30) NULL,
    [Spend]        MONEY         NULL,
    [Transactions] INT           NULL,
    [Customers]    INT           NULL
);

