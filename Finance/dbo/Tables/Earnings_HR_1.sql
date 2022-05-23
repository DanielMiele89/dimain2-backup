CREATE TABLE [dbo].[Earnings_HR] (
    [CustomerID]      INT          NOT NULL,
    [PublisherID]     INT          NOT NULL,
    [EarningSourceID] INT          NOT NULL,
    [TranDate]        VARCHAR (10) NOT NULL,
    [TransactionID]   BIGINT       NULL,
    [SourceID]        BIGINT       NULL,
    [Earnings]        INT          NOT NULL
);

