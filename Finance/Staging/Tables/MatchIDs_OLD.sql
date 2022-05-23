CREATE TABLE [Staging].[MatchIDs_OLD] (
    [ID]            INT        NULL,
    [TypeID]        TINYINT    NULL,
    [ItemID]        INT        NULL,
    [FanID]         INT        NULL,
    [Price]         SMALLMONEY NULL,
    [Date]          DATETIME   NULL,
    [ProcessDate]   DATETIME   NULL,
    [MatchID]       INT        NULL,
    [VectorID]      TINYINT    NULL,
    [VectorMajorID] INT        NULL,
    [VectorMInorID] INT        NULL,
    [ClubCash]      SMALLMONEY NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [Staging].[MatchIDs_OLD]([MatchID] ASC);


GO
CREATE NONCLUSTERED INDEX [NIX]
    ON [Staging].[MatchIDs_OLD]([FanID] ASC)
    INCLUDE([MatchID]);

