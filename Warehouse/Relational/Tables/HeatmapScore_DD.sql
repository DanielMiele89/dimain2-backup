CREATE TABLE [Relational].[HeatmapScore_DD] (
    [ID]           INT        IDENTITY (1, 1) NOT NULL,
    [BrandID]      INT        NOT NULL,
    [ComboID]      INT        NOT NULL,
    [HeatmapIndex] FLOAT (53) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

