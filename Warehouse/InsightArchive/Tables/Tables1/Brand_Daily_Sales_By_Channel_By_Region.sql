CREATE TABLE [InsightArchive].[Brand_Daily_Sales_By_Channel_By_Region] (
    [BrandName]               VARCHAR (50) NOT NULL,
    [TranDate]                DATE         NULL,
    [Region]                  VARCHAR (30) NULL,
    [IsOnline]                BIT          NOT NULL,
    [Sales_2020]              MONEY        NULL,
    [Transactions_2020]       INT          NULL,
    [Equiv_Sales_2019]        MONEY        NULL,
    [Equiv_Transactions_2019] INT          NULL
);

