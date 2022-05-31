CREATE TABLE [SamW].[UAEResearch] (
    [Spend]        MONEY          NULL,
    [Transactions] INT            NULL,
    [Date]         DATETIME       NULL,
    [CINID]        INT            NOT NULL,
    [Age_Group]    VARCHAR (12)   NULL,
    [Social_Class] NVARCHAR (255) NULL,
    [Region]       VARCHAR (30)   NULL,
    [TypeDesc]     VARCHAR (50)   NOT NULL,
    [BrandName]    VARCHAR (50)   NOT NULL,
    [CountryName]  VARCHAR (100)  NULL
);

