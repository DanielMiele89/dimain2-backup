CREATE TABLE [tasfia].[PJ_SOW] (
    [GroupName]         VARCHAR (16) NOT NULL,
    [BrandName]         VARCHAR (50) NOT NULL,
    [PreLockdownCust]   INT          NULL,
    [PreLockdownSpend]  MONEY        NULL,
    [PreLockdownTrans]  INT          NULL,
    [PostLockdownCust]  INT          NULL,
    [PostLockdownSpend] MONEY        NULL,
    [PostLockdownTrans] INT          NULL,
    [Pre_ATV]           MONEY        NOT NULL,
    [Lockdown_ATV]      MONEY        NOT NULL
);

