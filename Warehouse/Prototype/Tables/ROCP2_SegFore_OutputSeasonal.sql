CREATE TABLE [Prototype].[ROCP2_SegFore_OutputSeasonal] (
    [BrandID]           INT          NULL,
    [MonthID2]          VARCHAR (10) NULL,
    [Sales_adj]         REAL         NULL,
    [Spender_adj]       REAL         NULL,
    [Avgw_Sales]        REAL         NULL,
    [Avgw_Spder]        INT          NULL,
    [Avgw_Sales_BASE]   REAL         NULL,
    [Avgw_Spender_BASE] INT          NULL,
    [Cardholders]       REAL         NULL
);


GO
CREATE CLUSTERED INDEX [IDX_BID]
    ON [Prototype].[ROCP2_SegFore_OutputSeasonal]([BrandID] ASC);

