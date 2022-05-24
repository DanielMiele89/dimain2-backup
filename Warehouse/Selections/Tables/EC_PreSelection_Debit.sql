CREATE TABLE [Selections].[EC_PreSelection_Debit] (
    [FanID] INT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_ECPreSelectionDebit_Fan]
    ON [Selections].[EC_PreSelection_Debit]([FanID] ASC) WITH (FILLFACTOR = 90);

