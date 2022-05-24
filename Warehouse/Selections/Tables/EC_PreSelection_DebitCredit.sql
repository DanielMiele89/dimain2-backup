CREATE TABLE [Selections].[EC_PreSelection_DebitCredit] (
    [FanID] INT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_ECPreSelectionDebitCredit_Fan]
    ON [Selections].[EC_PreSelection_DebitCredit]([FanID] ASC) WITH (FILLFACTOR = 90);

