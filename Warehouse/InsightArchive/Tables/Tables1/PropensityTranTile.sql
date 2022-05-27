CREATE TABLE [InsightArchive].[PropensityTranTile] (
    [ID]           INT      IDENTITY (1, 1) NOT NULL,
    [BrandID]      SMALLINT NOT NULL,
    [Tile]         TINYINT  NOT NULL,
    [MinTranCount] INT      NOT NULL,
    [MaxTranCount] INT      NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

