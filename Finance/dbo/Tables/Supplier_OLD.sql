CREATE TABLE [dbo].[Supplier_OLD] (
    [SupplierID]      INT           NOT NULL,
    [Description]     VARCHAR (100) NULL,
    [Status]          INT           NOT NULL,
    [CreatedDateTime] DATETIME2 (7) NOT NULL,
    [UpdatedDateTime] DATETIME2 (7) NULL,
    CONSTRAINT [PK_Supplier_OLD] PRIMARY KEY CLUSTERED ([SupplierID] ASC) WITH (FILLFACTOR = 95)
);

