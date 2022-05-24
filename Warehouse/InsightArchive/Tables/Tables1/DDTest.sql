CREATE TABLE [InsightArchive].[DDTest] (
    [FileID]    INT           NOT NULL,
    [RowNum]    INT           NOT NULL,
    [Amount]    MONEY         NOT NULL,
    [OIN]       INT           NOT NULL,
    [DDDate]    DATE          NOT NULL,
    [Narrative] NVARCHAR (18) NOT NULL,
    [SourceUID] VARCHAR (20)  NULL,
    [FanID]     INT           NULL,
    PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);

