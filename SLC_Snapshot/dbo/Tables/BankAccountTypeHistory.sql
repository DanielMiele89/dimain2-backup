CREATE TABLE [dbo].[BankAccountTypeHistory] (
    [ID]            INT         IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [BankAccountID] INT         NOT NULL,
    [Type]          VARCHAR (3) NOT NULL,
    [StartDate]     DATETIME    NOT NULL,
    [EndDate]       DATETIME    NULL,
    [LoyaltyFlag]   VARCHAR (3) NULL,
    CONSTRAINT [PK_BankAccountTypeHistory] PRIMARY KEY CLUSTERED ([ID] ASC)
);

