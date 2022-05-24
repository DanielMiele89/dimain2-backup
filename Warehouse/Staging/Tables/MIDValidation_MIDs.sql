CREATE TABLE [Staging].[MIDValidation_MIDs] (
    [ID]                     INT            IDENTITY (1, 1) NOT NULL,
    [ValidationID]           INT            NULL,
    [ValidationDate]         DATETIME       NULL,
    [PartnerName]            NVARCHAR (255) NULL,
    [BrandID]                INT            NULL,
    [MerchantID]             NVARCHAR (50)  NULL,
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

