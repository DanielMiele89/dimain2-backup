CREATE TABLE [InsightArchive].[testtbl] (
    [ID]       INT          IDENTITY (1, 1) NOT NULL,
    [TestTxt]  VARCHAR (50) NOT NULL,
    [TestType] TINYINT      NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

