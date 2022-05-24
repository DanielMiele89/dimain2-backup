CREATE TABLE [Relational].[DD_DataDictionary_SupplierLookUp] (
    [LookUpID]         INT           IDENTITY (1, 1) NOT NULL,
    [SupplierID]       INT           NOT NULL,
    [SupplierWildcard] VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_LookUpID] PRIMARY KEY CLUSTERED ([LookUpID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_SuppWC]
    ON [Relational].[DD_DataDictionary_SupplierLookUp]([SupplierWildcard] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_SuppID]
    ON [Relational].[DD_DataDictionary_SupplierLookUp]([SupplierID] ASC);

