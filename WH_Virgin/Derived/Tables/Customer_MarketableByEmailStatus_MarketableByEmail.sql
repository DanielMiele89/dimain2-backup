CREATE TABLE [Derived].[Customer_MarketableByEmailStatus_MarketableByEmail] (
    [FanID]             INT  NOT NULL,
    [MarketableByEmail] BIT  NOT NULL,
    [StartDate]         DATE NOT NULL,
    [EndDate]           DATE NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_FanIDDates]
    ON [Derived].[Customer_MarketableByEmailStatus_MarketableByEmail]([FanID] ASC, [StartDate] ASC, [EndDate] ASC);

