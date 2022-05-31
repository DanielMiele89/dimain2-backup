CREATE TABLE [tasfia].[WETS_Lockdown] (
    [GroupName]      VARCHAR (9)  NOT NULL,
    [Sector]         VARCHAR (50) NULL,
    [SubSector]      VARCHAR (50) NULL,
    [Brand]          VARCHAR (50) NOT NULL,
    [TotalSpend]     MONEY        NULL,
    [Transactions]   INT          NULL,
    [Customers]      INT          NULL,
    [LockdownPeriod] VARCHAR (10) NULL,
    [CountGroup]     INT          NULL
);

