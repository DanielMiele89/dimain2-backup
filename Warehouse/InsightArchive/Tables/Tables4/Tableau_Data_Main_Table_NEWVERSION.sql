CREATE TABLE [InsightArchive].[Tableau_Data_Main_Table_NEWVERSION] (
    [TranDate]        DATE         NULL,
    [IsMyRewards]     BIT          NULL,
    [BrandID]         SMALLINT     NULL,
    [BrandName]       VARCHAR (50) NULL,
    [Custom Sector]   VARCHAR (23) NULL,
    [SectorName]      VARCHAR (50) NULL,
    [GroupName]       VARCHAR (50) NULL,
    [IsOnline]        BIT          NULL,
    [IsReturn]        TINYINT      NULL,
    [Sales]           MONEY        NOT NULL,
    [Transactions]    INT          NOT NULL,
    [Equiv_Sales]     MONEY        NOT NULL,
    [Equiv_Trans]     INT          NOT NULL,
    [Pre_Equiv_Sales] MONEY        NOT NULL,
    [Pre_Equiv_Trans] INT          NOT NULL
);

