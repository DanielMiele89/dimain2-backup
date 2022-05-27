CREATE TABLE [Staging].[MIDValidation_Import] (
    [ID]                     INT           IDENTITY (1, 1) NOT NULL,
    [BrandID]                VARCHAR (255) NULL,
    [MerchantID]             VARCHAR (255) NULL,
    [AddressLine1]           VARCHAR (255) NULL,
    [AddressLine2]           VARCHAR (255) NULL,
    [City]                   VARCHAR (255) NULL,
    [Postcode]               VARCHAR (255) NULL,
    [County]                 VARCHAR (255) NULL,
    [ContactPhone]           VARCHAR (255) NULL,
    [PartnerOutletReference] VARCHAR (255) NULL,
    [Channel]                VARCHAR (255) NULL,
    [MIDType]                VARCHAR (255) NULL,
    [Notes]                  VARCHAR (150) NULL
);

