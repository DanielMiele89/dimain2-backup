CREATE TABLE [Relational].[ShareOfWallet_SegmentCounts_Prior35] (
    [ID]              INT     IDENTITY (1, 1) NOT NULL,
    [ShareofWalletID] INT     NULL,
    [HTMID]           TINYINT NULL,
    [Members]         INT     NULL,
    [PCT_Customer]    REAL    NULL,
    [AverageSpend]    MONEY   NULL,
    [AverageLoyalty]  REAL    NULL
);

