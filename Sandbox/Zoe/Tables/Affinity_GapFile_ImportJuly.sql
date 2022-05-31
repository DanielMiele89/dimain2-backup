CREATE TABLE [Zoe].[Affinity_GapFile_ImportJuly] (
    [ProxyUserID]                 VARCHAR (50) NULL,
    [AuthorisationDate]           VARCHAR (50) NULL,
    [MerchantID]                  VARCHAR (50) NULL,
    [BrandName]                   VARCHAR (50) NULL,
    [BrandID]                     VARCHAR (50) NULL,
    [MerchantDescriptor]          VARCHAR (50) NULL,
    [MCCCode]                     VARCHAR (50) NULL,
    [MerchantLocation]            VARCHAR (50) NULL,
    [MerchantPostcode]            VARCHAR (50) NULL,
    [TransactionAmount]           VARCHAR (50) NULL,
    [CurrencyCode]                VARCHAR (50) NULL,
    [CardholderPresentFlag]       VARCHAR (50) NULL,
    [CardType]                    VARCHAR (50) NULL,
    [PerturbedAmount]             VARCHAR (50) NULL,
    [Variance]                    VARCHAR (50) NULL,
    [RandomNumber]                VARCHAR (50) NULL,
    [CardholderLocationIndicator] VARCHAR (50) NULL,
    [FileID]                      VARCHAR (50) NULL,
    [RowNum]                      VARCHAR (50) NULL
);


GO
CREATE CLUSTERED INDEX [idx_fileid_rownum]
    ON [Zoe].[Affinity_GapFile_ImportJuly]([FileID] ASC, [RowNum] ASC);

