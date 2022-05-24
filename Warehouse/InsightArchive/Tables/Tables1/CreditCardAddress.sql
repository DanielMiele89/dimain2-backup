CREATE TABLE [InsightArchive].[CreditCardAddress] (
    [brandid]              SMALLINT        NULL,
    [MerchantID]           NVARCHAR (15)   NULL,
    [MerchantDBAName]      NVARCHAR (25)   NULL,
    [MerchantSICClassCode] NVARCHAR (4)    NULL,
    [MerchantDBAState]     NVARCHAR (3)    NULL,
    [MerchantDBACity]      NVARCHAR (13)   NULL,
    [MerchantDBACountry]   NVARCHAR (3)    NULL,
    [First_Tran]           VARCHAR (10)    NULL,
    [Last_Tran]            VARCHAR (10)    NULL,
    [No_Trans]             INT             NULL,
    [MerchantZip]          NVARCHAR (4000) NULL,
    [Valid_UK_Postcode]    VARCHAR (1)     NOT NULL,
    [Site_No]              BIGINT          NULL
);

