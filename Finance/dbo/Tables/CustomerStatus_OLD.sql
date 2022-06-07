CREATE TABLE [dbo].[CustomerStatus_OLD] (
    [CustomerStatusID] SMALLINT      NOT NULL,
    [Name]             VARCHAR (25)  NOT NULL,
    [Description]      VARCHAR (200) NULL,
    CONSTRAINT [PK_CustomerStatus_OLD] PRIMARY KEY CLUSTERED ([CustomerStatusID] ASC)
);

