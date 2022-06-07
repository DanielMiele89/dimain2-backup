CREATE TABLE [AWS].[FileUploadLog] (
    [ID]           INT            IDENTITY (1, 1) NOT NULL,
    [ServerName]   [sysname]      NOT NULL,
    [FileName]     NVARCHAR (256) NOT NULL,
    [LoggedDate]   DATETIME       CONSTRAINT [df_AWSFileUploadLog_LoggedDate] DEFAULT (getdate()) NOT NULL,
    [UploadedDate] DATETIME       NULL,
    [ProcessRunID] INT            NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 95)
);

