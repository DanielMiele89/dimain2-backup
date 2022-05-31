CREATE TABLE [SamW].[MorrisonsCompetitor] (
    [Customers]         INT          NULL,
    [Spend]             MONEY        NULL,
    [Transactions]      INT          NULL,
    [BrandName]         VARCHAR (50) NOT NULL,
    [Period]            VARCHAR (8)  NOT NULL,
    [PreviousCustomers] INT          NOT NULL,
    [NewTo]             INT          NOT NULL
);

