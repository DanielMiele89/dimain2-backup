CREATE TABLE [Prototype].[ROCEFT_SegmentOutput] (
    [ID]           INT   IDENTITY (1, 1) NOT NULL,
    [DateRow]      INT   NULL,
    [BrandID]      INT   NULL,
    [Segment]      INT   NULL,
    [Sales]        MONEY NULL,
    [OnlineSales]  MONEY NULL,
    [Transactions] INT   NULL,
    [Shoppers]     INT   NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

