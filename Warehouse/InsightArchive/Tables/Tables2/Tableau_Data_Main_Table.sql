CREATE TABLE [InsightArchive].[Tableau_Data_Main_Table] (
    [TranDate]         DATE         NULL,
    [IsMyRewards]      BIT          NULL,
    [BrandID]          SMALLINT     NOT NULL,
    [BrandName]        VARCHAR (50) NULL,
    [Custom Sector]    VARCHAR (50) NULL,
    [SectorName]       VARCHAR (50) NULL,
    [GroupName]        VARCHAR (50) NULL,
    [IsOnline]         BIT          NOT NULL,
    [IsReturn]         INT          NOT NULL,
    [DEMO]             VARCHAR (50) NULL,
    [Demographic Type] VARCHAR (50) NULL,
    [Sales]            MONEY        NOT NULL,
    [Transactions]     INT          NOT NULL,
    [Equiv_Sales]      MONEY        NOT NULL,
    [Equiv_Trans]      INT          NOT NULL
);

