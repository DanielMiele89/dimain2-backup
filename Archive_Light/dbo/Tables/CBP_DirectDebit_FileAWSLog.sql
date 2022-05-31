CREATE TABLE [dbo].[CBP_DirectDebit_FileAWSLog] (
    [FileID]           INT      NOT NULL,
    [AWSLoadDateStart] DATETIME NOT NULL,
    [IsDownloaded]     BIT      NOT NULL,
    CONSTRAINT [PK_CBP_DirectDebit_FileAWSLog] PRIMARY KEY CLUSTERED ([FileID] ASC)
);

