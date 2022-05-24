CREATE TABLE [ExcelQuery].[AmexModelNaturalSales] (
    [BrandID]      INT              NULL,
    [CycleID]      BIGINT           NULL,
    [CycleStart]   DATE             NULL,
    [CycleEnd]     DATE             NULL,
    [Segment]      VARCHAR (7)      NULL,
    [SegmentSize]  INT              NULL,
    [Sales]        MONEY            NOT NULL,
    [OnlineSales]  MONEY            NOT NULL,
    [Transactions] INT              NOT NULL,
    [Spenders]     INT              NOT NULL,
    [RR]           NUMERIC (25, 14) NULL,
    [SPS]          MONEY            NULL,
    [SPC]          MONEY            NULL,
    [TPC]          NUMERIC (25, 14) NULL
);

