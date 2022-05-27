CREATE TABLE [Prototype].[ROCP2_SegFore_Fi_NaturalSales] (
    [BrandID]            SMALLINT     NULL,
    [Segment]            VARCHAR (25) NULL,
    [Timepoint]          SMALLINT     NULL,
    [Counts]             INT          NULL,
    [AVGw_Sales]         MONEY        NULL,
    [AVGw_Spder]         REAL         NULL,
    [AVGw_Sales_InStore] MONEY        NULL,
    [AVGw_Spder_InStore] REAL         NULL
);


GO
CREATE CLUSTERED INDEX [IDX_BrandID]
    ON [Prototype].[ROCP2_SegFore_Fi_NaturalSales]([BrandID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_Seg]
    ON [Prototype].[ROCP2_SegFore_Fi_NaturalSales]([Segment] ASC);

