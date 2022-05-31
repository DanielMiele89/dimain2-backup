CREATE TABLE [SamW].[JDSportsInsight] (
    [Customers]                 INT          NULL,
    [Transactions]              INT          NULL,
    [PositiveTransactions]      MONEY        NULL,
    [NegativeTransactions]      MONEY        NULL,
    [WeekNo]                    INT          NULL,
    [WeekStartDate]             DATE         NULL,
    [IsOnline]                  BIT          NOT NULL,
    [BrandName]                 VARCHAR (50) NOT NULL,
    [PaymentType]               VARCHAR (8)  NULL,
    [OnlinePreLockdownSpenders] INT          NULL,
    [InstorePurcashers]         INT          NULL,
    [OnlineLockdownSpenders]    INT          NULL,
    [NewToSector]               INT          NULL
);

