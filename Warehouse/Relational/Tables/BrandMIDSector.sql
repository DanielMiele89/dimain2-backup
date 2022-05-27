CREATE TABLE [Relational].[BrandMIDSector] (
    [BrandMIDID] INT      NOT NULL,
    [BrandID]    SMALLINT NOT NULL,
    [SectorID]   TINYINT  NOT NULL,
    CONSTRAINT [PK_BrandMIDSector] PRIMARY KEY CLUSTERED ([BrandMIDID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_BrandMIDSector_BrandID]
    ON [Relational].[BrandMIDSector]([BrandID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_BrandMIDSector_SectorID]
    ON [Relational].[BrandMIDSector]([SectorID] ASC);

