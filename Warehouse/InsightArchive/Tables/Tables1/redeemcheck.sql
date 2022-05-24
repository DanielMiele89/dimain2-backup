CREATE TABLE [InsightArchive].[redeemcheck] (
    [id]         INT      IDENTITY (1, 1) NOT NULL,
    [FanID]      INT      NOT NULL,
    [RedeemDate] DATETIME NOT NULL,
    [Cashback]   MONEY    NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

