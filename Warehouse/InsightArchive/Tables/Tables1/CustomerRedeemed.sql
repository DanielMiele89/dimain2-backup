CREATE TABLE [InsightArchive].[CustomerRedeemed] (
    [FanID]           INT   NOT NULL,
    [RedemptionValue] MONEY NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

