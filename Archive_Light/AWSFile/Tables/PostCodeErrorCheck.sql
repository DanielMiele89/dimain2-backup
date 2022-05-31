CREATE TABLE [AWSFile].[PostCodeErrorCheck] (
    [id]                   INT          NOT NULL,
    [MerchantID]           VARCHAR (15) NULL,
    [MerchantDBAName]      VARCHAR (25) NULL,
    [MerchantSICClassCode] VARCHAR (4)  NULL,
    [MerchantDBAState]     VARCHAR (3)  NULL,
    [MerchantDBACity]      VARCHAR (13) NULL,
    [MerchantZip]          VARCHAR (50) NULL,
    [MerchantDBACountry]   VARCHAR (3)  NULL,
    [First_Tran]           DATE         NULL,
    [Last_Tran]            DATE         NULL,
    [Amount]               MONEY        NULL,
    [No_Trans]             INT          NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

