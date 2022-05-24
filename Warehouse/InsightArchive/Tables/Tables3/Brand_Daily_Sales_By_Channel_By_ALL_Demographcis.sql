CREATE TABLE [InsightArchive].[Brand_Daily_Sales_By_Channel_By_ALL_Demographcis] (
    [TranDate]                DATE           NULL,
    [BrandName]               VARCHAR (50)   NOT NULL,
    [GroupName]               VARCHAR (50)   NULL,
    [SectorName]              VARCHAR (50)   NULL,
    [AgeCurrentBandText]      VARCHAR (10)   NULL,
    [Region]                  VARCHAR (30)   NULL,
    [Social_Class]            NVARCHAR (255) NULL,
    [IsOnline]                BIT            NOT NULL,
    [Sales_2020]              MONEY          NULL,
    [Transactions_2020]       INT            NULL,
    [Equiv_Sales_2019]        MONEY          NULL,
    [Equiv_Transactions_2019] INT            NULL
);

