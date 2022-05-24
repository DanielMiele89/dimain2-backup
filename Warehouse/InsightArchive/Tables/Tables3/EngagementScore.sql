CREATE TABLE [InsightArchive].[EngagementScore] (
    [FanID]            INT          NOT NULL,
    [CINID]            VARCHAR (50) NULL,
    [SourceUID]        VARCHAR (20) NULL,
    [ClubID]           INT          NULL,
    [Classification]   VARCHAR (50) NULL,
    [Engagement_Score] INT          NULL,
    [Engagement_Rank]  BIGINT       NULL
);

