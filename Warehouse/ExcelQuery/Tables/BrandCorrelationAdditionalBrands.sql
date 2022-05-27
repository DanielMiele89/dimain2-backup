CREATE TABLE [ExcelQuery].[BrandCorrelationAdditionalBrands] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]   INT          NULL,
    [BrandName] VARCHAR (50) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

