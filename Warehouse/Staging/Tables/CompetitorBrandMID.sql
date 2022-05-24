CREATE TABLE [Staging].[CompetitorBrandMID] (
    [BrandID]          INT           NULL,
    [BrandName]        VARCHAR (100) NULL,
    [TransactionText]  VARCHAR (22)  NULL,
    [MerchantID]       VARCHAR (15)  NULL,
    [TransactionCount] BIGINT        NULL,
    [TransactionATV]   MONEY         NULL,
    [MCC]              VARCHAR (50)  NULL
);

