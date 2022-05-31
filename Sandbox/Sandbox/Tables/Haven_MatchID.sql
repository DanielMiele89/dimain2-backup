CREATE TABLE [Sandbox].[Haven_MatchID] (
    [MatchID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_MatchID]
    ON [Sandbox].[Haven_MatchID]([MatchID] ASC);

