CREATE TABLE [Relational].[ShareOfWallet_SegmentCounts] (
    [ID]              INT     IDENTITY (1, 1) NOT NULL,
    [ShareofWalletID] INT     NULL,
    [HTMID]           TINYINT NULL,
    [Members]         INT     NULL,
    [PCT_Customer]    REAL    NULL,
    [AverageSpend]    MONEY   NULL,
    [AverageLoyalty]  REAL    NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

