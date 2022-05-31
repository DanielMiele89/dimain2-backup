CREATE TABLE [tasfia].[WETS_Lockdown_FB] (
    [GroupName]      VARCHAR (8)  NOT NULL,
    [Sector]         VARCHAR (50) NULL,
    [SubSector]      VARCHAR (50) NULL,
    [Brand]          VARCHAR (50) NOT NULL,
    [TranDate]       DATE         NOT NULL,
    [TotalSpend]     MONEY        NULL,
    [Transactions]   INT          NULL,
    [Customers]      INT          NULL,
    [LockdownPeriod] VARCHAR (10) NULL
);

