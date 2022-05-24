CREATE TABLE [Prototype].[Hack_EngagementScore] (
    [FanID]       INT NOT NULL,
    [EmailEvents] INT NULL,
    [WebLogins]   INT NULL,
    [Marketable]  BIT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

