CREATE TABLE [Staging].[MIDValidation_MIDs_Import] (
    [ID]                     INT            IDENTITY (1, 1) NOT NULL,
    [PartnerName]            NVARCHAR (255) NULL,
    [BrandID]                NVARCHAR (255) NULL,
    [MerchantID]             NVARCHAR (255) NULL,
    [AddressLine1]           NVARCHAR (255) NULL,
    [AddressLine2]           NVARCHAR (255) NULL,
    [City]                   NVARCHAR (255) NULL,
    [Postcode]               NVARCHAR (255) NULL,
    [County]                 NVARCHAR (255) NULL,
    [ContactPhone]           NVARCHAR (255) NULL,
    [PartnerOutletReference] NVARCHAR (255) NULL,
    [Channel]                NVARCHAR (255) NULL,
    [Notes]                  NVARCHAR (255) NULL
);

