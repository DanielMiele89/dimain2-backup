CREATE TABLE [MI].[SSAS_DimCustomer] (
    [CustomerID] INT          NOT NULL,
    [DOB]        DATE         NULL,
    [Gender]     VARCHAR (10) NOT NULL,
    [PostCode]   VARCHAR (10) NOT NULL,
    CONSTRAINT [PK_MI_SSAS_DimCustomer] PRIMARY KEY CLUSTERED ([CustomerID] ASC)
);

