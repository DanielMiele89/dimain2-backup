CREATE TABLE [dbo].[DirectDebitCategory2] (
    [ID]       INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ParentID] INT          NOT NULL,
    [Name]     VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_DirectDebitCategory2] PRIMARY KEY CLUSTERED ([ID] ASC)
);

