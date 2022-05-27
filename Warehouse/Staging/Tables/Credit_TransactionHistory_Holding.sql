CREATE TABLE [Staging].[Credit_TransactionHistory_Holding] (
    [FileID]                     INT           NOT NULL,
    [RowNum]                     INT           NOT NULL,
    [TransactionReferenceNumber] NVARCHAR (23) NULL,
    [MerchantDBACountry]         NVARCHAR (3)  NULL,
    [MerchantID]                 NVARCHAR (15) NULL,
    [MerchantAccountNumber]      NVARCHAR (16) NULL,
    [MerchantDBAName]            NVARCHAR (25) NULL,
    [MerchantDBACity]            NVARCHAR (13) NULL,
    [MerchantDBAState]           NVARCHAR (3)  NULL,
    [MerchantSICClassCode]       NVARCHAR (4)  NULL,
    [MerchantZip]                NVARCHAR (9)  NULL,
    [CIN]                        NVARCHAR (15) NULL,
    [CardholderPresentMC]        CHAR (1)      NULL,
    [Amount]                     SMALLMONEY    NULL,
    [TranDate]                   VARCHAR (10)  NULL,
    CONSTRAINT [PK_Staging_Credit_TransactionHistory_Holding] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC) WITH (DATA_COMPRESSION = PAGE)
);

