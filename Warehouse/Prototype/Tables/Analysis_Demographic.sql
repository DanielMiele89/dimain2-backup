CREATE TABLE [Prototype].[Analysis_Demographic] (
    [Gender]                CHAR (1)      NULL,
    [AgeBand]               VARCHAR (12)  NULL,
    [CAMEO]                 VARCHAR (151) NOT NULL,
    [BaseDistribution]      INT           NULL,
    [SelectionDistribution] INT           NULL,
    [BrandName]             VARCHAR (50)  NULL,
    [Sales]                 MONEY         NULL,
    [Trans]                 INT           NULL,
    [Shoppers]              INT           NULL
);

