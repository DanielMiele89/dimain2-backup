CREATE TABLE [Relational].[Customer_Engagement_History] (
    [RowID]         BIGINT       IDENTITY (1, 1) NOT NULL,
    [FanID]         INT          NOT NULL,
    [Cohort]        DATE         NULL,
    [Updatedate]    DATE         NULL,
    [SpendScore]    INT          DEFAULT ((0)) NULL,
    [InteractScore] INT          DEFAULT ((0)) NULL,
    [EngageScore]   INT          DEFAULT ((0)) NULL,
    [Segment]       VARCHAR (20) DEFAULT ('Unengaged') NULL,
    PRIMARY KEY CLUSTERED ([RowID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [idx_ceh_fanid_updatedate]
    ON [Relational].[Customer_Engagement_History]([FanID] ASC, [Updatedate] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

