CREATE TABLE [Selections].[EC_PreSelection_Credit] (
    [FanID] INT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_ECPreSelectionCredit_Fan]
    ON [Selections].[EC_PreSelection_Credit]([FanID] ASC) WITH (FILLFACTOR = 90);

