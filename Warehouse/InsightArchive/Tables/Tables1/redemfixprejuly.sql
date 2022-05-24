CREATE TABLE [InsightArchive].[redemfixprejuly] (
    [id]           INT      IDENTITY (1, 1) NOT NULL,
    [redeemdate]   DATETIME NOT NULL,
    [cashbackused] MONEY    NOT NULL,
    [fanid]        INT      NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

