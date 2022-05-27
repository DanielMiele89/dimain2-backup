CREATE TABLE [InsightArchive].[Email_opening_score] (
    [fanid]            INT        NOT NULL,
    [Scoring_Date]     DATE       NOT NULL,
    [Open_score]       FLOAT (53) DEFAULT ((0)) NULL,
    [Open_rank]        BIGINT     DEFAULT ((0)) NULL,
    [Override_Applied] TINYINT    DEFAULT ((0)) NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_Scoring_Date]
    ON [InsightArchive].[Email_opening_score]([Scoring_Date] ASC, [fanid] ASC, [Open_score] ASC) WITH (FILLFACTOR = 95);

