CREATE TABLE [dbo].[BankAccountTransaction] (
    [ID]            INT        IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [BankAccountID] INT        NULL,
    [Amount]        SMALLMONEY NULL,
    [TransID]       INT        NULL,
    [TransDate]     DATETIME   NULL,
    [Status]        INT        NULL,
    [Reported]      BIT        NOT NULL,
    [ExportFileID]  INT        NOT NULL,
    CONSTRAINT [PK_BankAccountTransaction] PRIMARY KEY CLUSTERED ([ID] ASC)
);

