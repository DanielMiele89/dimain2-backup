CREATE TABLE [Relational].[DD_HeatmapScore] (
    [ID]           INT        IDENTITY (1, 1) NOT NULL,
    [BrandID]      INT        NOT NULL,
    [ComboID]      INT        NOT NULL,
    [HeatmapIndex] FLOAT (53) NOT NULL
);

