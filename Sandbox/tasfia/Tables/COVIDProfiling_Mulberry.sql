CREATE TABLE [tasfia].[COVIDProfiling_Mulberry] (
    [BrandName]          VARCHAR (50)   NOT NULL,
    [Gender]             CHAR (1)       NULL,
    [AgeCurrentBandText] VARCHAR (10)   NULL,
    [Region]             VARCHAR (30)   NULL,
    [PostalSector]       VARCHAR (6)    NULL,
    [Social_Class]       NVARCHAR (255) NULL,
    [PrePost]            VARCHAR (8)    NOT NULL,
    [MeanAge]            INT            NULL,
    [Spend]              MONEY          NULL,
    [Customers]          INT            NULL,
    [Transactions]       INT            NULL,
    [FirstTranDate]      DATE           NULL
);

