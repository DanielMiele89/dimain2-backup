CREATE TABLE [dbo].[DirectDebitCategory1] (
    [ID]   INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Name] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_DirectDebitCategory1] PRIMARY KEY CLUSTERED ([ID] ASC)
);

