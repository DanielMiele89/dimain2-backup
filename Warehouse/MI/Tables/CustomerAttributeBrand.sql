CREATE TABLE [MI].[CustomerAttributeBrand] (
    [ID]            INT      IDENTITY (1, 1) NOT NULL,
    [BrandID]       SMALLINT NOT NULL,
    [AttributeType] TINYINT  NOT NULL,
    CONSTRAINT [PK_MI_CustomerAttributeBrand] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_MI_CustomerAttributeBrand_Type] FOREIGN KEY ([AttributeType]) REFERENCES [MI].[CustomerAttributeType] ([ID]),
    CONSTRAINT [UQ_MI_CustomerAttributeBrand] UNIQUE NONCLUSTERED ([BrandID] ASC, [AttributeType] ASC)
);

