CREATE TABLE [tasfia].[TBForecasting] (
    [Spend]                     MONEY         NULL,
    [Transactions]              INT           NULL,
    [Customers]                 INT           NULL,
    [SELECTION]                 INT           NULL,
    [CustomerSegmentOnTranDate] VARCHAR (7)   NOT NULL,
    [CycleStartDate]            DATE          NULL,
    [BrandName]                 VARCHAR (500) NULL
);

