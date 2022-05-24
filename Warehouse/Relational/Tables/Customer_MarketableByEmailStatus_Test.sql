CREATE TABLE [Relational].[Customer_MarketableByEmailStatus_Test] (
    [ID]                INT  IDENTITY (1, 1) NOT NULL,
    [FanID]             INT  NOT NULL,
    [MarketableByEmail] BIT  NOT NULL,
    [StartDate]         DATE NOT NULL,
    [EndDate]           DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

