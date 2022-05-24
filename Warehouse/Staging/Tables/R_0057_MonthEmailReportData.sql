CREATE TABLE [Staging].[R_0057_MonthEmailReportData] (
    [FanID]        INT          NOT NULL,
    [ClubID]       INT          NOT NULL,
    [CampaignKey]  VARCHAR (15) NOT NULL,
    [CJS]          CHAR (3)     NOT NULL,
    [WeekNumber]   TINYINT      NOT NULL,
    [SentOK]       TINYINT      NOT NULL,
    [Opened]       TINYINT      NOT NULL,
    [Clicked]      TINYINT      NOT NULL,
    [Unsubscribed] TINYINT      NOT NULL
);

