CREATE TABLE [Relational].[Outlet] (
    [OutletID]     INT           NOT NULL,
    [MerchantID]   VARCHAR (50)  NOT NULL,
    [PartnerID]    INT           NOT NULL,
    [Address1]     VARCHAR (100) NULL,
    [Address2]     VARCHAR (100) NULL,
    [City]         VARCHAR (100) NULL,
    [Postcode]     VARCHAR (10)  NULL,
    [PostalSector] VARCHAR (6)   NULL,
    [PostArea]     VARCHAR (2)   NULL,
    [Region]       VARCHAR (30)  NULL,
    PRIMARY KEY CLUSTERED ([OutletID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Outlet_PartnerID]
    ON [Relational].[Outlet]([PartnerID] ASC);

