CREATE TABLE [AWSFile].[PostCode_NewLocations_FirstStage] (
    [ID]                   INT          IDENTITY (1, 1) NOT NULL,
    [MerchantID]           VARCHAR (15) NOT NULL,
    [MerchantDBAName]      VARCHAR (25) NOT NULL,
    [MerchantSICClassCode] VARCHAR (4)  NOT NULL,
    [MerchantDBAState]     VARCHAR (3)  NOT NULL,
    [MerchantDBACity]      VARCHAR (13) NOT NULL,
    [MerchantZip]          VARCHAR (50) NOT NULL,
    [MerchantDBACountry]   VARCHAR (3)  NOT NULL,
    [First_Tran]           DATE         NOT NULL,
    [Last_Tran]            DATE         NOT NULL,
    [Amount]               MONEY        NULL,
    [No_Trans]             INT          NOT NULL,
    CONSTRAINT [PK_AWSFile_PostCode_NewLocations_FirstStage] PRIMARY KEY CLUSTERED ([ID] ASC)
);

