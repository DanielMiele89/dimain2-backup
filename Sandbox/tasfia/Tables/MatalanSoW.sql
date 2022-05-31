CREATE TABLE [tasfia].[MatalanSoW] (
    [GroupName]         VARCHAR (18)  NOT NULL,
    [BrandName]         VARCHAR (50)  NOT NULL,
    [PreLockdownCust]   INT           NULL,
    [PreLockdownSpend]  MONEY         NULL,
    [PostLockdownCust]  INT           NULL,
    [PostLockdownSpend] MONEY         NULL,
    [MainBrand]         VARCHAR (500) NULL,
    [ReportName]        VARCHAR (500) NULL,
    [Version]           INT           NULL
);

