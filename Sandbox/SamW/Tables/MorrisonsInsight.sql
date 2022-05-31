CREATE TABLE [SamW].[MorrisonsInsight] (
    [Customers]                 INT          NULL,
    [BrandName]                 VARCHAR (50) NOT NULL,
    [CustomerSegmentOnTranDate] VARCHAR (7)  NOT NULL,
    [WeekNo]                    INT          NULL,
    [StartDate]                 DATE         NULL,
    [Spend]                     MONEY        NULL,
    [Transactions]              INT          NULL,
    [MoreCardholders]           INT          NOT NULL
);

