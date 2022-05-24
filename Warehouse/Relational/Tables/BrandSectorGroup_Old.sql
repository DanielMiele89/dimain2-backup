CREATE TABLE [Relational].[BrandSectorGroup_Old] (
    [SectorGroupID] TINYINT      IDENTITY (1, 1) NOT NULL,
    [GroupName]     VARCHAR (50) NULL,
    CONSTRAINT [PK_BrandSectorGroup] PRIMARY KEY CLUSTERED ([SectorGroupID] ASC)
);

