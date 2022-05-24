CREATE TABLE [Prototype].[HeatmapCombinations] (
    [ComboID]           INT          IDENTITY (1, 1) NOT NULL,
    [Gender]            VARCHAR (10) NULL,
    [HeatmapAgeGroup]   VARCHAR (20) NULL,
    [HeatmapCameoGroup] VARCHAR (50) NULL,
    [IsUnknown]         BIT          NULL,
    PRIMARY KEY CLUSTERED ([ComboID] ASC)
);

