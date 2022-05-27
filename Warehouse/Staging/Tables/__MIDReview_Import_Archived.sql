CREATE TABLE [Staging].[__MIDReview_Import_Archived] (
    [ID]                     INT           IDENTITY (1, 1) NOT NULL,
    [MerchantID]             VARCHAR (100) NULL,
    [AddressLine1]           VARCHAR (150) NULL,
    [AddressLine2]           VARCHAR (150) NULL,
    [City]                   VARCHAR (150) NULL,
    [Postcode]               VARCHAR (150) NULL,
    [County]                 VARCHAR (150) NULL,
    [ContactPhone]           VARCHAR (150) NULL,
    [PartnerOutletReference] VARCHAR (150) NULL,
    [Channel]                VARCHAR (150) NULL,
    [MIDType]                VARCHAR (150) NULL,
    [Notes]                  VARCHAR (150) NULL,
    [MIDListType]            VARCHAR (150) NULL
);

