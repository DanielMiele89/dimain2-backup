CREATE TABLE [Lion].[BOPE_BrandCommercialRank] (
    [ID]             INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]        INT          NOT NULL,
    [BrandName]      VARCHAR (50) NOT NULL,
    [CommercialRank] INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_BOPEBrandCommercialRank_BrandIDRank]
    ON [Lion].[BOPE_BrandCommercialRank]([BrandID] ASC, [CommercialRank] ASC);

