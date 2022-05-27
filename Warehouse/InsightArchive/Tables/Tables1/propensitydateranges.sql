CREATE TABLE [InsightArchive].[propensitydateranges] (
    [id]        TINYINT IDENTITY (1, 1) NOT NULL,
    [StartDate] DATE    NOT NULL,
    [EndDate]   DATE    NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

