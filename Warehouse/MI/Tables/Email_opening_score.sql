CREATE TABLE [MI].[Email_opening_score] (
    [fanid]            INT        NOT NULL,
    [Scoring_Date]     DATE       NOT NULL,
    [Open_score]       FLOAT (53) DEFAULT ((0)) NULL,
    [Open_rank]        BIGINT     DEFAULT ((0)) NULL,
    [Override_Applied] TINYINT    DEFAULT ((0)) NULL,
    PRIMARY KEY CLUSTERED ([fanid] ASC)
);

