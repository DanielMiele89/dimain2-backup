CREATE TABLE [Prototype].[CreditTrans_MIDDetails_AllFiles] (
    [MerchantDBACountry]         NVARCHAR (3)  NULL,
    [MerchantID]                 NVARCHAR (15) NULL,
    [MerchantDBAName]            NVARCHAR (25) NULL,
    [MerchantDBACity]            NVARCHAR (13) NULL,
    [MerchantDBAState]           NVARCHAR (3)  NULL,
    [MerchantSICClassCode]       NVARCHAR (4)  NULL,
    [MerchantZIP]                NVARCHAR (9)  NULL,
    [TransactionReferenceNumber] NVARCHAR (23) NULL,
    [CurrencyCode]               NVARCHAR (3)  NULL,
    [FirstTran]                  VARCHAR (10)  NULL,
    [MaxTran]                    VARCHAR (10)  NULL,
    [Trans]                      INT           NULL
);


GO
CREATE COLUMNSTORE INDEX [CSI_All]
    ON [Prototype].[CreditTrans_MIDDetails_AllFiles]([MerchantDBACountry], [MerchantID], [MerchantDBAName], [MerchantDBACity], [MerchantDBAState], [MerchantSICClassCode], [MerchantZIP], [TransactionReferenceNumber], [CurrencyCode], [FirstTran], [MaxTran], [Trans])
    ON [Warehouse_Columnstores];

