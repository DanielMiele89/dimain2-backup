CREATE TABLE [Relational].[BrandTag] (
    [BrandTagID] TINYINT      IDENTITY (1, 1) NOT NULL,
    [Tag]        VARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([BrandTagID] ASC),
    CONSTRAINT [UQ_BrandTag_Tag] UNIQUE NONCLUSTERED ([Tag] ASC)
);

