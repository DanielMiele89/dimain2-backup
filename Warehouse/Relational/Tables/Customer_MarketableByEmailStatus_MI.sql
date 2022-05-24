CREATE TABLE [Relational].[Customer_MarketableByEmailStatus_MI] (
    [ID]           INT     IDENTITY (1, 1) NOT NULL,
    [FanID]        INT     NOT NULL,
    [MarketableID] TINYINT NOT NULL,
    [StartDate]    DATE    NOT NULL,
    [EndDate]      DATE    NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Customer_Loyalty_Invites_FanID]
    ON [Relational].[Customer_MarketableByEmailStatus_MI]([FanID] ASC) WITH (FILLFACTOR = 80);

