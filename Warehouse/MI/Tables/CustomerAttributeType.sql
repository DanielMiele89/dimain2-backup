CREATE TABLE [MI].[CustomerAttributeType] (
    [ID]       TINYINT      IDENTITY (1, 1) NOT NULL,
    [TypeDesc] VARCHAR (50) NULL,
    CONSTRAINT [PK_MI_CustomerAttributeType] PRIMARY KEY CLUSTERED ([ID] ASC)
);

