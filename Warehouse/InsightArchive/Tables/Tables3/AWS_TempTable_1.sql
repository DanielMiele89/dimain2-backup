CREATE TABLE [InsightArchive].[AWS_TempTable_1] (
    [CINID]             INT              NULL,
    [MB_Spend_Period1]  MONEY            NULL,
    [MB_Spend_Period2]  MONEY            NULL,
    [CAT_Spend_Period1] MONEY            NULL,
    [CAT_Spend_Period2] MONEY            NULL,
    [MB_Trans_Period1]  INT              NULL,
    [MB_Trans_Period2]  INT              NULL,
    [CAT_Trans_Period1] INT              NULL,
    [CAT_Trans_Period2] INT              NULL,
    [SOW_Period1]       DECIMAL (12, 11) NULL,
    [SOW_Period2]       DECIMAL (12, 11) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_Stuff]
    ON [InsightArchive].[AWS_TempTable_1]([CINID] ASC);


GO
CREATE COLUMNSTORE INDEX [NonClusteredColumnStoreIndex-20171205-083958]
    ON [InsightArchive].[AWS_TempTable_1]([CAT_Spend_Period1], [CINID])
    ON [Warehouse_Columnstores];

