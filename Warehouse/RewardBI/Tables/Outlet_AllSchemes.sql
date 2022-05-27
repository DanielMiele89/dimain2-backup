CREATE TABLE [RewardBI].[Outlet_AllSchemes] (
    [OutletID]       INT           IDENTITY (1, 1) NOT NULL,
    [SchemeID]       TINYINT       NOT NULL,
    [SourceOutletID] INT           NOT NULL,
    [MID]            VARCHAR (50)  NOT NULL,
    [PartnerID]      INT           NOT NULL,
    [Address1]       VARCHAR (100) NULL,
    [Address2]       VARCHAR (100) NULL,
    [City]           VARCHAR (100) NULL,
    [Postcode]       VARCHAR (10)  NULL,
    [PostalSector]   VARCHAR (6)   NULL,
    [PostArea]       VARCHAR (2)   NULL,
    [Region]         VARCHAR (30)  NULL,
    CONSTRAINT [PK_RewardBI_Outlet_AllSchemes] PRIMARY KEY CLUSTERED ([OutletID] ASC),
    CONSTRAINT [UQ_RewardBI_Outlet_AllSchemes_Source] UNIQUE NONCLUSTERED ([SchemeID] ASC, [SourceOutletID] ASC)
);

