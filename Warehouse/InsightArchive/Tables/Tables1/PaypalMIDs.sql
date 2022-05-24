CREATE TABLE [InsightArchive].[PaypalMIDs] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [MID]       VARCHAR (50) NOT NULL,
    [Narrative] VARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

