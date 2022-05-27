CREATE TABLE [Relational].[BrandTagBrand] (
    [BrandTagBrandID] INT      IDENTITY (1, 1) NOT NULL,
    [BrandID]         SMALLINT NOT NULL,
    [BrandTagID]      TINYINT  NOT NULL,
    PRIMARY KEY CLUSTERED ([BrandTagBrandID] ASC),
    CONSTRAINT [FK_BrandTagBrand_Brand] FOREIGN KEY ([BrandID]) REFERENCES [Relational].[Brand_Old] ([BrandID]),
    CONSTRAINT [FK_BrandTagBrand_BrandTag] FOREIGN KEY ([BrandTagID]) REFERENCES [Relational].[BrandTag] ([BrandTagID])
);

