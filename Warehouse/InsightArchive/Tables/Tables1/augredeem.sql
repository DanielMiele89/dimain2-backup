CREATE TABLE [InsightArchive].[augredeem] (
    [id]           INT      IDENTITY (1, 1) NOT NULL,
    [cashbackUsed] MONEY    NOT NULL,
    [FanID]        INT      NOT NULL,
    [redeemdate]   DATETIME NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

