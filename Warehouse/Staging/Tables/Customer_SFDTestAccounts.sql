CREATE TABLE [Staging].[Customer_SFDTestAccounts] (
    [FanID] INT NULL
);


GO
CREATE NONCLUSTERED INDEX [idx_Customer_SFDTestAccounts_FanID]
    ON [Staging].[Customer_SFDTestAccounts]([FanID] ASC);

