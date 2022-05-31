CREATE TABLE [kevinc].[Customers] (
    [custid]       INT           IDENTITY (1, 1) NOT NULL,
    [companyname]  NVARCHAR (40) NOT NULL,
    [contactname]  NVARCHAR (30) NOT NULL,
    [contacttitle] NVARCHAR (30) NOT NULL,
    [address]      NVARCHAR (60) NOT NULL,
    [city]         NVARCHAR (15) NOT NULL,
    [region]       NVARCHAR (15) NULL,
    [postalcode]   NVARCHAR (10) NULL,
    [country]      NVARCHAR (15) NOT NULL,
    [phone]        NVARCHAR (24) NOT NULL,
    [fax]          NVARCHAR (24) NULL,
    CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED ([custid] ASC)
);


GO
CREATE NONCLUSTERED INDEX [idx_nc_city]
    ON [kevinc].[Customers]([city] ASC);


GO
CREATE NONCLUSTERED INDEX [idx_nc_companyname]
    ON [kevinc].[Customers]([companyname] ASC);


GO
CREATE NONCLUSTERED INDEX [idx_nc_postalcode]
    ON [kevinc].[Customers]([postalcode] ASC);


GO
CREATE NONCLUSTERED INDEX [idx_nc_region]
    ON [kevinc].[Customers]([region] ASC);

