CREATE TABLE [dbo].[CustomerContactCode] (
    [ID]          INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Description] NVARCHAR (50) NOT NULL,
    CONSTRAINT [PK_CustomerContactCode] PRIMARY KEY CLUSTERED ([ID] ASC)
);

