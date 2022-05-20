CREATE TABLE [dbo].[IssuerCustomerAttribute] (
    [ID]               INT         IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [IssuerCustomerID] INT         NOT NULL,
    [AttributeID]      INT         NOT NULL,
    [StartDate]        DATETIME    NOT NULL,
    [EndDate]          DATETIME    NULL,
    [Value]            VARCHAR (8) NULL,
    CONSTRAINT [PK_IssuerCustomerAttribute] PRIMARY KEY CLUSTERED ([ID] ASC)
);

