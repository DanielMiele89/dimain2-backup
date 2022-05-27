CREATE TABLE [Relational].[HeatmapScore_POS] (
    [ID]           INT        IDENTITY (1, 1) NOT NULL,
    [BrandID]      INT        NOT NULL,
    [ComboID]      INT        NOT NULL,
    [HeatmapIndex] FLOAT (53) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_BrandCombo]
    ON [Relational].[HeatmapScore_POS]([BrandID] ASC, [ComboID] ASC) WITH (FILLFACTOR = 80);

