CREATE TABLE [Staging].[TransHistoryByMonth] (
    [CustomerID]       BIGINT       NULL,
    [TransactionText]  VARCHAR (22) NULL,
    [MerchantID]       VARCHAR (15) NULL,
    [MerchantCatCode]  VARCHAR (4)  NULL,
    [MerchantCountry]  VARCHAR (20) NULL,
    [TransactionMonth] DATE         NULL,
    [SalesAmount]      MONEY        NULL,
    [SalesCount]       SMALLINT     NULL,
    [BrandIDFromText]  INT          NULL,
    [BrandIDFromMID]   INT          NULL,
    [BrandIDFinal]     INT          NULL
);


GO
CREATE NONCLUSTERED INDEX [i_MerchantID]
    ON [Staging].[TransHistoryByMonth]([MerchantID] ASC);

