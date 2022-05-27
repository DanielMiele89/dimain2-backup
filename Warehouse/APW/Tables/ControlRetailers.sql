CREATE TABLE [APW].[ControlRetailers] (
    [PartnerID]   INT           NOT NULL,
    [BrandID]     SMALLINT      NOT NULL,
    [PartnerName] VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_APW_ControlRetailers] PRIMARY KEY CLUSTERED ([PartnerID] ASC)
);

