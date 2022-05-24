CREATE TABLE [Derived].[BalanceAdjustments_Goodwill] (
    [ID]               INT           IDENTITY (1, 1) NOT NULL,
    [FanID]            INT           NULL,
    [GoodwillAmount]   MONEY         NULL,
    [GoodwillDateTime] DATETIME2 (7) NULL,
    [GoodwillTypeID]   INT           NOT NULL,
    [AddedDate]        DATETIME2 (7) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

