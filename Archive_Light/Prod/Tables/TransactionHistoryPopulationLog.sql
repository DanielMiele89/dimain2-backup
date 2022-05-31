CREATE TABLE [Prod].[TransactionHistoryPopulationLog] (
    [ID]           INT      IDENTITY (1, 1) NOT NULL,
    [TableCode]    CHAR (1) NOT NULL,
    [FileID]       INT      NOT NULL,
    [CopyStarted]  DATETIME CONSTRAINT [df_TranHistPopLog_CopyStart] DEFAULT (getdate()) NOT NULL,
    [CopyFinished] DATETIME NULL
);

