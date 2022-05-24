CREATE TABLE [Staging].[MIDValidation_Details] (
    [ID]             INT            IDENTITY (1, 1) NOT NULL,
    [ValidationID]   INT            NULL,
    [ValidationDate] DATETIME       NULL,
    [PartnerID]      INT            NULL,
    [BrandID]        INT            NULL,
    [MIDListType]    NVARCHAR (255) NULL,
    [RetailerType]   NVARCHAR (255) NULL
);

