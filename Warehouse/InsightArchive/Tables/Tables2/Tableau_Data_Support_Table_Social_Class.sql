CREATE TABLE [InsightArchive].[Tableau_Data_Support_Table_Social_Class] (
    [TranDate]      DATE           NULL,
    [IsMyRewards]   BIT            NULL,
    [BrandID]       SMALLINT       NOT NULL,
    [BrandName]     VARCHAR (50)   NOT NULL,
    [Custom Sector] VARCHAR (23)   NULL,
    [SectorName]    VARCHAR (50)   NULL,
    [GroupName]     VARCHAR (50)   NULL,
    [IsOnline]      BIT            NOT NULL,
    [IsReturn]      INT            NOT NULL,
    [Social_Class]  NVARCHAR (255) NOT NULL,
    [Sales]         MONEY          NOT NULL,
    [Transactions]  INT            NOT NULL,
    [Equiv_Sales]   MONEY          NOT NULL,
    [Equiv_Trans]   INT            NOT NULL
);

