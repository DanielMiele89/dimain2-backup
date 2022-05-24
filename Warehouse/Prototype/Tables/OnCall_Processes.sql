CREATE TABLE [Prototype].[OnCall_Processes] (
    [Job_ID]       UNIQUEIDENTIFIER NOT NULL,
    [SupportLevel] INT              NOT NULL,
    [ArchiveDate]  DATE             NULL,
    [isArchived]   BIT              CONSTRAINT [DF_Archived] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_OnCallPID] PRIMARY KEY CLUSTERED ([Job_ID] ASC),
    CONSTRAINT [FK_OnCallSupportLevel] FOREIGN KEY ([SupportLevel]) REFERENCES [Prototype].[OnCall_SupportLevel] ([SupportLevel])
);

