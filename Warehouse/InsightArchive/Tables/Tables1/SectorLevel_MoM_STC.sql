CREATE TABLE [InsightArchive].[SectorLevel_MoM_STC] (
    [ID]           INT          IDENTITY (1, 1) NOT NULL,
    [Year]         INT          NULL,
    [Month]        INT          NULL,
    [Sector]       VARCHAR (60) NULL,
    [Group]        VARCHAR (60) NULL,
    [IsOnline]     INT          NULL,
    [Spend]        FLOAT (53)   NULL,
    [Transactions] INT          NULL,
    [Customers]    INT          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

