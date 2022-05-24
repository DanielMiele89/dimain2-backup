CREATE TABLE [AWS].[S3Upload_Log] (
    [LogID]           INT           IDENTITY (1, 1) NOT NULL,
    [RunID]           INT           NOT NULL,
    [Msg]             VARCHAR (MAX) NULL,
    [CreatedDateTime] DATETIME2 (7) CONSTRAINT [DF_AWS_S3Upload_Log_CreatedDateTime] DEFAULT (getdate()) NOT NULL,
    [isError]         BIT           NOT NULL,
    CONSTRAINT [PK_AWS_S3Upload_Log] PRIMARY KEY CLUSTERED ([LogID] ASC)
);

