CREATE TABLE [MI].[CustomerAttributeMCC] (
    [ID]            INT      IDENTITY (1, 1) NOT NULL,
    [MCCID]         SMALLINT NOT NULL,
    [AttributeType] TINYINT  NOT NULL,
    CONSTRAINT [PK_MI_CustomerAttributeMCC] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_MI_CustomerAttributeMCC_Type] FOREIGN KEY ([AttributeType]) REFERENCES [MI].[CustomerAttributeType] ([ID]),
    CONSTRAINT [UQ_MI_CustomerAttributeMCC] UNIQUE NONCLUSTERED ([MCCID] ASC, [AttributeType] ASC)
);

