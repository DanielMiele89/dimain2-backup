CREATE TABLE [Relational].[Customer_MarketableByEmailStatus] (
    [ID]                INT  IDENTITY (1, 1) NOT NULL,
    [FanID]             INT  NOT NULL,
    [MarketableByEmail] BIT  NOT NULL,
    [StartDate]         DATE NOT NULL,
    [EndDate]           DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_EndDate]
    ON [Relational].[Customer_MarketableByEmailStatus]([EndDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_StartDate]
    ON [Relational].[Customer_MarketableByEmailStatus]([StartDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Relational].[Customer_MarketableByEmailStatus]([FanID] ASC);

