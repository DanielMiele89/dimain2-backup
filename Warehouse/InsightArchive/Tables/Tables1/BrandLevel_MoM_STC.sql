CREATE TABLE [InsightArchive].[BrandLevel_MoM_STC] (
    [ID]           INT          IDENTITY (1, 1) NOT NULL,
    [Year]         INT          NULL,
    [Month]        INT          NULL,
    [Brand]        VARCHAR (60) NULL,
    [Sector]       VARCHAR (60) NULL,
    [Spend]        FLOAT (53)   NULL,
    [Transactions] INT          NULL,
    [Customers]    INT          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

