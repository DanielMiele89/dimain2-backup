CREATE TABLE [Prototype].[PartnerDetails] (
    [BrandID]          VARCHAR (30)   NULL,
    [PartnerID]        INT            NOT NULL,
    [PartnerName]      NVARCHAR (100) NOT NULL,
    [Matcher]          NVARCHAR (50)  NOT NULL,
    [MerchantAcquirer] NVARCHAR (100) NULL,
    [Status]           NVARCHAR (20)  NOT NULL
);

