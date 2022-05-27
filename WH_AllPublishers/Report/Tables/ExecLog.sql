CREATE TABLE [Report].[ExecLog] (
    [LogID]           INT           IDENTITY (1, 1) NOT NULL,
    [Msg]             VARCHAR (MAX) NULL,
    [isError]         BIT           NOT NULL,
    [ExecCommand]     VARCHAR (MAX) NULL,
    [CreatedDateTime] DATETIME      CONSTRAINT [DF_Processing_ExecLog_Compression_CreatedDateTime] DEFAULT (getdate()) NOT NULL,
    [RunID]           INT           NOT NULL
);

