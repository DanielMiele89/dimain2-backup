CREATE TABLE [tasfia].[NikeShoppers] (
    [BrandName]         VARCHAR (50) NOT NULL,
    [GroupName]         VARCHAR (11) NOT NULL,
    [PreLockdownSpend]  MONEY        NULL,
    [PostLockdownSpend] MONEY        NULL,
    [Customers]         INT          NULL,
    [TotalSpend]        MONEY        NULL,
    [TotalTrans]        INT          NULL,
    [Pre_ATV]           MONEY        NOT NULL,
    [Lockdown_ATV]      MONEY        NOT NULL
);

