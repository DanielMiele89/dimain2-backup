CREATE TABLE [Derived].[Customer_EmailAddressChanges] (
    [ID]          INT            IDENTITY (1, 1) NOT NULL,
    [FanID]       INT            NOT NULL,
    [Email]       NVARCHAR (255) NULL,
    [DateChanged] DATE           NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

