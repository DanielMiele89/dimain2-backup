CREATE TABLE [InsightArchive].[DurationTest] (
    [id]              INT     IDENTITY (1, 1) NOT NULL,
    [DurationID]      TINYINT NOT NULL,
    [DurationDiff]    TINYINT NOT NULL,
    [TargetMonthDate] DATE    NOT NULL,
    [StartDate]       DATE    NOT NULL,
    [EndDate]         DATE    NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

