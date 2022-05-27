CREATE TABLE [Derived].[Outlet] (
    [OutletID]               INT             NOT NULL,
    [PartnerID]              INT             NOT NULL,
    [PartnerOutletReference] NVARCHAR (20)   NULL,
    [MerchantID]             NVARCHAR (4000) NULL,
    [Status]                 INT             NOT NULL,
    [Channel]                TINYINT         NOT NULL,
    [IsOnline]               BIT             NULL,
    [Address1]               NVARCHAR (100)  NULL,
    [Address2]               NVARCHAR (100)  NULL,
    [City]                   NVARCHAR (100)  NULL,
    [Postcode]               NVARCHAR (10)   NULL,
    [PostalSector]           VARCHAR (6)     NULL,
    [PostArea]               VARCHAR (2)     NULL,
    [Region]                 VARCHAR (30)    NULL,
    [Latitude]               VARCHAR (50)    NULL,
    [Longitude]              VARCHAR (50)    NULL,
    [AddedDate]              DATETIME2 (7)   NOT NULL,
    [ModifiedDate]           DATETIME2 (7)   NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_OutletID]
    ON [Derived].[Outlet]([OutletID] ASC);

