CREATE TABLE [InsightArchive].[RedeemTest] (
    [id]           INT   IDENTITY (1, 1) NOT NULL,
    [FanID]        INT   NOT NULL,
    [Redeemdate]   DATE  NOT NULL,
    [CashbackUsed] MONEY NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

