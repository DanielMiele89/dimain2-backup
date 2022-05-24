CREATE TABLE [Derived].[Customer_MarketableByEmailStatus] (
    [ID]                    INT          IDENTITY (1, 1) NOT NULL,
    [FanID]                 INT          NOT NULL,
    [CurrentlyActive]       BIT          NOT NULL,
    [Hardbounced]           BIT          NOT NULL,
    [Unsubscribed]          BIT          NOT NULL,
    [MarketableByEmail]     BIT          NOT NULL,
    [MarketableByEmailType] VARCHAR (20) NOT NULL,
    [StartDate]             DATE         NOT NULL,
    [EndDate]               DATE         NULL,
    [MarketableByPush]      BIT          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_FanIDDates]
    ON [Derived].[Customer_MarketableByEmailStatus]([FanID] ASC, [StartDate] ASC, [EndDate] ASC);

