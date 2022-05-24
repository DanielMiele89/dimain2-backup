CREATE TABLE [InsightArchive].[BrandLevel_MoM_STC_v2] (
    [ID]           INT          IDENTITY (1, 1) NOT NULL,
    [Year]         INT          NULL,
    [Month]        INT          NULL,
    [Brand]        VARCHAR (60) NULL,
    [Sector]       VARCHAR (60) NULL,
    [Group]        VARCHAR (60) NULL,
    [IsOnline]     INT          NULL,
    [Spend]        FLOAT (53)   NULL,
    [Transactions] INT          NULL,
    [Customers]    INT          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

