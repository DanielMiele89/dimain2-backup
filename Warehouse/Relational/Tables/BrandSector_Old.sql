CREATE TABLE [Relational].[BrandSector_Old] (
    [SectorID]      TINYINT      IDENTITY (1, 1) NOT NULL,
    [SectorGroupID] TINYINT      NULL,
    [SectorName]    VARCHAR (50) NULL,
    CONSTRAINT [PK_BrandSector] PRIMARY KEY CLUSTERED ([SectorID] ASC),
    CONSTRAINT [FK_BrandSector_BrandSectorGroup] FOREIGN KEY ([SectorGroupID]) REFERENCES [Relational].[BrandSectorGroup_Old] ([SectorGroupID]),
    CONSTRAINT [FK_BrandSector_BrandSectorGroup_v2] FOREIGN KEY ([SectorGroupID]) REFERENCES [Relational].[BrandSectorGroup_Old] ([SectorGroupID])
);


GO
CREATE NONCLUSTERED INDEX [IX_BrandSector_SectorGroupID]
    ON [Relational].[BrandSector_Old]([SectorGroupID] ASC);

