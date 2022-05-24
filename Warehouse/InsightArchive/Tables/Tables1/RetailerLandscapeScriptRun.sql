CREATE TABLE [InsightArchive].[RetailerLandscapeScriptRun] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [ScriptStart] DATETIME NOT NULL,
    [ScriptEnd]   DATETIME NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

