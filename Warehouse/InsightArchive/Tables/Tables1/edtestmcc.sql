CREATE TABLE [InsightArchive].[edtestmcc] (
    [MerchantID]           NVARCHAR (15)   NULL,
    [MerchantDBAName]      NVARCHAR (25)   NULL,
    [MerchantSICClassCode] NVARCHAR (4)    NULL,
    [MerchantDBAState]     NVARCHAR (3)    NULL,
    [MerchantDBACity]      NVARCHAR (13)   NULL,
    [MerchantDBACountry]   NVARCHAR (3)    NULL,
    [MerchantZip]          NVARCHAR (4000) NULL,
    [Valid_UK_Postcode]    VARCHAR (1)     NULL,
    [MID]                  VARCHAR (15)    NULL,
    [Narrative]            VARCHAR (25)    NULL,
    [MCC]                  VARCHAR (50)    NULL,
    [Town]                 VARCHAR (13)    NULL,
    [LocationCountry]      VARCHAR (3)     NULL,
    [PostCode]             VARCHAR (10)    NULL,
    [IsValidUKPostCode]    BIT             NULL
);

