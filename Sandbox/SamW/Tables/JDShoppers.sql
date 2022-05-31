CREATE TABLE [SamW].[JDShoppers] (
    [BrandName]         VARCHAR (50) NOT NULL,
    [Spenders]          VARCHAR (15) NULL,
    [PreLockdownSpend]  MONEY        NULL,
    [PostLockdownSpend] MONEY        NULL,
    [Customers]         INT          NULL,
    [TotalSpend]        MONEY        NULL,
    [TotalTrans]        INT          NULL,
    [Pre_ATV]           MONEY        NOT NULL,
    [Lockdown_ATV]      MONEY        NOT NULL
);

