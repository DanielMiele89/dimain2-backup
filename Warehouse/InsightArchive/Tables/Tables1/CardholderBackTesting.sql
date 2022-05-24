CREATE TABLE [InsightArchive].[CardholderBackTesting] (
    [ID]         INT IDENTITY (1, 1) NOT NULL,
    [DateRow]    INT NULL,
    [BrandID]    INT NULL,
    [Segment]    INT NULL,
    [Population] INT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

