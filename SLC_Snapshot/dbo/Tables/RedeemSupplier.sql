CREATE TABLE [dbo].[RedeemSupplier] (
    [ID]          INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Description] NVARCHAR (100) NOT NULL,
    [Status]      INT            NOT NULL,
    CONSTRAINT [PK_RedeemSupplier] PRIMARY KEY CLUSTERED ([ID] ASC)
);

