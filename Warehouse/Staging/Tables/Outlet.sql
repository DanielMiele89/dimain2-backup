CREATE TABLE [Staging].[Outlet] (
    [OutletID]               INT           NOT NULL,
    [PartnerID]              INT           NOT NULL,
    [MerchantID]             NVARCHAR (50) NOT NULL,
    [Channel]                TINYINT       NOT NULL,
    [Address1]               VARCHAR (100) NULL,
    [Address2]               VARCHAR (100) NULL,
    [City]                   VARCHAR (100) NULL,
    [Postcode]               VARCHAR (10)  NULL,
    [PostalSector]           VARCHAR (6)   NULL,
    [PostArea]               VARCHAR (2)   NULL,
    [Region]                 VARCHAR (30)  NULL,
    [IsOnline]               BIT           NULL,
    [PartnerOutletReference] NVARCHAR (20) NULL
);

