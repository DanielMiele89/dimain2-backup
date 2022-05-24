CREATE TABLE [InsightArchive].[PropensityTargetSpender] (
    [ID]              INT          IDENTITY (1, 1) NOT NULL,
    [FanID_Month]     VARCHAR (50) NOT NULL,
    [IsTargetSpender] BIT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

