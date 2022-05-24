CREATE TABLE [WHB].[UserAgentParser_Log] (
    [LogID]           INT           IDENTITY (1, 1) NOT NULL,
    [LogInfo]         VARCHAR (MAX) NULL,
    [CreatedDateTime] DATETIME2 (7) CONSTRAINT [DF_WHB_UseragentParser_Log_CreatedDateTime] DEFAULT (getdate()) NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [WHB].[UserAgentParser_Log]([LogID] ASC);

