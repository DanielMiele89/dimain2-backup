CREATE TABLE [Relational].[DD_DataDictionary_Suppliers] (
    [SupplierID]           INT           IDENTITY (1, 1) NOT NULL,
    [SupplierName]         VARCHAR (250) NOT NULL,
    [Ext_SupplierCategory] VARCHAR (100) NULL,
    [RefusedByRBSG]        BIT           DEFAULT ((0)) NULL,
    CONSTRAINT [pk_SupplierID] PRIMARY KEY CLUSTERED ([SupplierID] ASC)
);

