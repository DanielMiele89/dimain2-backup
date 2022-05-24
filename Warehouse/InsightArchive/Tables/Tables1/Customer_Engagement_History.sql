CREATE TABLE [InsightArchive].[Customer_Engagement_History] (
    [RowID]         BIGINT       IDENTITY (1, 1) NOT NULL,
    [FanID]         INT          NOT NULL,
    [Cohort]        DATE         NULL,
    [Updatedate]    DATE         NULL,
    [SpendScore]    INT          NULL,
    [InteractScore] INT          NULL,
    [EngageScore]   INT          NULL,
    [Segment]       VARCHAR (20) NULL
);

