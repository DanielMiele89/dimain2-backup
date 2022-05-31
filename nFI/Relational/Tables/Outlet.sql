CREATE TABLE [Relational].[Outlet] (
    [ID]           INT           NOT NULL,
    [MerchantID]   VARCHAR (50)  NOT NULL,
    [PartnerID]    SMALLINT      NOT NULL,
    [Address1]     VARCHAR (100) NULL,
    [Address2]     VARCHAR (100) NULL,
    [City]         VARCHAR (100) NULL,
    [Postcode]     VARCHAR (10)  NULL,
    [PostalSector] VARCHAR (6)   NULL,
    [PostArea]     VARCHAR (2)   NULL,
    [Region]       VARCHAR (30)  NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_MID]
    ON [Relational].[Outlet]([MerchantID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_PID]
    ON [Relational].[Outlet]([PartnerID] ASC);

