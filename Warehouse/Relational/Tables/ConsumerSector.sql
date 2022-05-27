CREATE TABLE [Relational].[ConsumerSector] (
    [ConsumerCombinationID] INT      NOT NULL,
    [BrandID]               SMALLINT NOT NULL,
    [SectorID]              TINYINT  NOT NULL,
    CONSTRAINT [PK_Relational_ConsumerSector] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Relational_ConsumerSector_BrandSector]
    ON [Relational].[ConsumerSector]([BrandID] ASC, [SectorID] ASC);

