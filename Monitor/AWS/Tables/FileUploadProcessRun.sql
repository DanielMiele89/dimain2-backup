CREATE TABLE [AWS].[FileUploadProcessRun] (
    [ID]         INT       IDENTITY (1, 1) NOT NULL,
    [ServerName] [sysname] NOT NULL,
    [StartTime]  DATETIME  NOT NULL,
    [EndTime]    DATETIME  NULL
);

