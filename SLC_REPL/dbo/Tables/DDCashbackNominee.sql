CREATE TABLE [dbo].[DDCashbackNominee] (
    [ID]               INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [BankAccountID]    INT      NOT NULL,
    [IssuerCustomerID] INT      NOT NULL,
    [StartDate]        DATETIME NOT NULL,
    [EndDate]          DATETIME NULL,
    [RequestedBy]      INT      NULL,
    [ChangeSourceType] TINYINT  NULL,
    [ActionedBy]       INT      NULL,
    [ChangedDate]      DATETIME NULL,
    CONSTRAINT [PK_DDCashbackNominee] PRIMARY KEY CLUSTERED ([ID] ASC)
);

