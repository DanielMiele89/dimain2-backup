CREATE TABLE [tasfia].[HolidayInnExLocation] (
    [BrandName]        VARCHAR (50) NOT NULL,
    [Postcode]         VARCHAR (50) NOT NULL,
    [PostcodeDistrict] VARCHAR (50) NULL,
    [Region]           VARCHAR (30) NULL,
    [LockdownPeriod]   VARCHAR (10) NULL,
    [Spend]            MONEY        NULL,
    [Transactions]     INT          NULL,
    [Customers]        INT          NULL,
    [LockdownStart]    DATE         NULL,
    [LockdownMax]      DATE         NULL,
    [LYLockdownStart]  DATE         NULL,
    [LYLockdownMax]    DATE         NULL
);

