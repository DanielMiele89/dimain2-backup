CREATE TABLE [Monitor].[ProcessLog] (
    [LogID]       INT           IDENTITY (1, 1) NOT NULL,
    [ProcessName] VARCHAR (50)  NOT NULL,
    [ActionName]  VARCHAR (200) NOT NULL,
    [IsError]     BIT           CONSTRAINT [DF_MI_ProcessLog_IsError] DEFAULT ((0)) NOT NULL,
    [ActionDate]  DATETIME      CONSTRAINT [DF_MI_ProcessLog_ActionDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_MI_ProcessLog] PRIMARY KEY CLUSTERED ([LogID] ASC) WITH (FILLFACTOR = 90)
);

