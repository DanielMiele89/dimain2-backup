CREATE TABLE [Relational].[Customer_WebAccountLocked] (
    [FanID] INT NULL
);


GO
CREATE CLUSTERED INDEX [ix_customer_webaccountlocked_fanid]
    ON [Relational].[Customer_WebAccountLocked]([FanID] ASC);

