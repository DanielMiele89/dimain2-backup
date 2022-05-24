CREATE TABLE [InsightArchive].[PropensityCNRecentTile] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [BrandID]     SMALLINT NOT NULL,
    [Tile]        TINYINT  NOT NULL,
    [MinDayCount] INT      NOT NULL,
    [MaxDayCount] INT      NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

