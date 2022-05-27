CREATE TABLE [Relational].[PartnerBrands] (
    [PartnerBrandID] INT          IDENTITY (1, 1) NOT NULL,
    [PartnerID]      INT          NOT NULL,
    [BrandID]        INT          NOT NULL,
    [BrandName]      VARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([PartnerBrandID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerBrandID_BrandID]
    ON [Relational].[PartnerBrands]([BrandID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerBrandID_PartnerID]
    ON [Relational].[PartnerBrands]([PartnerID] ASC);

