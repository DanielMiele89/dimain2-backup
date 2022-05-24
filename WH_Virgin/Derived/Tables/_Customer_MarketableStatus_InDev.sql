CREATE TABLE [Derived].[_Customer_MarketableStatus_InDev] (
    [ID]                INT  IDENTITY (1, 1) NOT NULL,
    [FanID]             INT  NOT NULL,
    [CurrentlyActive]   BIT  NOT NULL,
    [Hardbounced]       BIT  NOT NULL,
    [Unsubscribed]      BIT  NOT NULL,
    [MarketableByEmail] BIT  NOT NULL,
    [MarketableByPush]  BIT  NOT NULL,
    [StartDate]         DATE NOT NULL,
    [EndDate]           DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

