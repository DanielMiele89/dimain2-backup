CREATE TABLE [InsightArchive].[Brand_Daily_Sales_By_Channel_By_ALL_Demographcis_HAM] (
    [BrandID]                 SMALLINT       NOT NULL,
    [BrandName]               VARCHAR (50)   NOT NULL,
    [GroupName]               VARCHAR (50)   NULL,
    [SectorName]              VARCHAR (50)   NULL,
    [Date]                    DATE           NULL,
    [AgeCurrentBandText]      VARCHAR (10)   NOT NULL,
    [Region]                  VARCHAR (30)   NOT NULL,
    [Social_Class]            NVARCHAR (255) NOT NULL,
    [IsOnline]                BIT            NOT NULL,
    [Sales]                   MONEY          NOT NULL,
    [Transactions]            INT            NOT NULL,
    [Equivalent_Sales]        MONEY          NOT NULL,
    [Equivalent_Transactions] INT            NOT NULL
);

