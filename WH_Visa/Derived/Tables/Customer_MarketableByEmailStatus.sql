CREATE TABLE [Derived].[Customer_MarketableByEmailStatus] (
    [ID]                    INT          IDENTITY (1, 1) NOT NULL,
    [FanID]                 INT          NOT NULL,
    [CurrentlyActive]       BIT          NOT NULL,
    [Hardbounced]           BIT          NOT NULL,
    [Unsubscribed]          BIT          NOT NULL,
    [EmailStructureValid]   BIT          NOT NULL,
    [MarketableByEmail]     BIT          NOT NULL,
    [EmailTracking]         BIT          NOT NULL,
    [MarketableByPush]      BIT          NOT NULL,
    [MarketableByEmailType] VARCHAR (20) NOT NULL,
    [StartDate]             DATE         NOT NULL,
    [EndDate]               DATE         NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

