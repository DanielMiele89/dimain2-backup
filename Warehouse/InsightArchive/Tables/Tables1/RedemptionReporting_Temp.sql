CREATE TABLE [InsightArchive].[RedemptionReporting_Temp] (
    [ID]               VARCHAR (60)    NULL,
    [Retailer]         VARCHAR (30)    NULL,
    [StartDate]        DATE            NULL,
    [EndDate]          DATE            NULL,
    [Period]           VARCHAR (15)    NULL,
    [Level]            VARCHAR (15)    NULL,
    [Cardholders]      BIGINT          NULL,
    [VouchersIssued]   BIGINT          NULL,
    [Sales]            DECIMAL (10, 2) NULL,
    [Trx]              BIGINT          NULL,
    [UniqueSpenders]   BIGINT          NULL,
    [IncrementalSales] DECIMAL (10, 2) NULL,
    [Investment]       DECIMAL (10, 2) NULL,
    [TotalSalesROI]    DECIMAL (6, 2)  NULL,
    [IncrementalROI]   DECIMAL (6, 2)  NULL,
    [FinancialROI]     DECIMAL (6, 2)  NULL,
    [SalesUplift]      DECIMAL (8, 4)  NULL,
    [SpendersUplift]   DECIMAL (8, 4)  NULL,
    [ATVUplift]        DECIMAL (8, 4)  NULL,
    [ATFUplift]        DECIMAL (8, 4)  NULL
);

