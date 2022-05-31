CREATE TABLE [SamW].[SportshoesInsight] (
    [Customers]           INT            NULL,
    [Transactions]        INT            NULL,
    [Spend]               MONEY          NULL,
    [Period]              VARCHAR (8)    NOT NULL,
    [SportshoesCustomers] INT            NOT NULL,
    [SportshoesLapsed]    INT            NOT NULL,
    [BrandName]           VARCHAR (50)   NOT NULL,
    [Social_Class]        NVARCHAR (255) NULL,
    [Region]              VARCHAR (30)   NULL,
    [AgeCurrentBandText]  VARCHAR (10)   NULL
);

