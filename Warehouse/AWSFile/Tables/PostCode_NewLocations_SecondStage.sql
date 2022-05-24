CREATE TABLE [AWSFile].[PostCode_NewLocations_SecondStage] (
    [ID]                   INT          IDENTITY (1, 1) NOT NULL,
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
    [Site_No]              BIGINT       NULL,
    [ValidUKPostCode]      BIT          NULL,
    CONSTRAINT [PK_AWSFile_PostCode_NewLocations_SecondStage] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_MerchantID]
    ON [AWSFile].[PostCode_NewLocations_SecondStage]([MerchantID] ASC, [MerchantDBAName] ASC)
    INCLUDE([MerchantZip]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

