CREATE TABLE [InsightArchive].[CaffeNero_NewAdditions] (
    [OutletID]     INT            NOT NULL,
    [IsOnline]     BIT            NULL,
    [MerchantID]   NVARCHAR (50)  NOT NULL,
    [PartnerID]    INT            NOT NULL,
    [Address1]     NVARCHAR (100) NULL,
    [Address2]     NVARCHAR (100) NULL,
    [City]         NVARCHAR (100) NULL,
    [PostCode]     NVARCHAR (20)  NULL,
    [PostalSector] VARCHAR (6)    NULL,
    [PostArea]     VARCHAR (2)    NULL,
    [Region]       VARCHAR (30)   NULL
);

