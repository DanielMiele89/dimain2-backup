CREATE TABLE [Staging].[CardTransaction_QA] (
    [FileID]         INT      NOT NULL,
    [FileCount]      INT      NOT NULL,
    [MatchedCount]   INT      NOT NULL,
    [UnmatchedCount] INT      NOT NULL,
    [NoCINCount]     INT      NOT NULL,
    [PositiveCount]  INT      NOT NULL,
    [QADate]         DATETIME CONSTRAINT [DF_Staging_CardTransaction_QA] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_CardTransactionQA] PRIMARY KEY CLUSTERED ([FileID] ASC)
);

