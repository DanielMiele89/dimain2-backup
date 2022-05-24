CREATE TABLE [ExcelQuery].[MVP_NaturalSalesByCycle] (
    [PKID]                INT          IDENTITY (1, 1) NOT NULL,
    [RunDate]             DATE         NULL,
    [GroupName]           VARCHAR (50) NULL,
    [BrandID]             INT          NULL,
    [ID]                  INT          NULL,
    [Seasonality_CycleID] INT          NULL,
    [Segment]             VARCHAR (20) NULL,
    [PropensityRank]      TINYINT      NULL,
    [EngagementRank]      TINYINT      NULL,
    [Population]          INT          NULL,
    [TotalSales]          MONEY        NULL,
    [OnlineSales]         MONEY        NULL,
    [TotalTrans]          INT          NULL,
    [OnlineTrans]         INT          NULL,
    [TotalShoppers]       INT          NULL,
    [OnlineShoppers]      INT          NULL,
    PRIMARY KEY CLUSTERED ([PKID] ASC)
);

