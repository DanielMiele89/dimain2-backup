CREATE TABLE [InsightArchive].[CustomerEngagementScoring] (
    [FanID]                    INT             NOT NULL,
    [No_Redemptions]           INT             NULL,
    [ClickEvents]              INT             NULL,
    [OpenEvents]               INT             NULL,
    [WebsiteLogins]            INT             NULL,
    [EngagementScore]          NUMERIC (17, 3) NULL,
    [EngagementQuartileOrNone] BIGINT          NULL
);

