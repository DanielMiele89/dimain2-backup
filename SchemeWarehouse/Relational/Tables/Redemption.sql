CREATE TABLE [Relational].[Redemption] (
    [RedemptionID]     INT      IDENTITY (1, 1) NOT NULL,
    [FanID]            INT      NOT NULL,
    [TranID]           INT      NOT NULL,
    [RedemptionItemID] INT      NOT NULL,
    [RedemptionDate]   DATETIME NOT NULL,
    [CashbackUsed]     MONEY    NULL,
    PRIMARY KEY CLUSTERED ([RedemptionID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Redemption_RedemptionDate]
    ON [Relational].[Redemption]([RedemptionDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Redemption_FanID]
    ON [Relational].[Redemption]([FanID] ASC);

