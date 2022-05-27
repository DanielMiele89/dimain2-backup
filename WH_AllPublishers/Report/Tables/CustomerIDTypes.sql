CREATE TABLE [Report].[CustomerIDTypes] (
    [CustomerIDTypeID]   TINYINT      IDENTITY (1, 1) NOT NULL,
    [CustomerIDTypeDesc] VARCHAR (50) NULL,
    [SourceTable]        VARCHAR (50) NULL,
    [SourceColumn]       VARCHAR (50) NULL
);

