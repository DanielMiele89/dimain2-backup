CREATE TABLE [MI].[SSAS_Customer_Staging] (
    [CustomerID] INT          IDENTITY (1, 1) NOT NULL,
    [SchemeID]   BIGINT       NOT NULL,
    [SchemeName] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_MI_SSAS_Customer_Staging] PRIMARY KEY CLUSTERED ([CustomerID] ASC)
);

