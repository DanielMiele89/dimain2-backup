CREATE TABLE [InsightArchive].[salespack_top_level_figures] (
    [BrandName]    VARCHAR (50) NOT NULL,
    [IsOnline]     VARCHAR (1)  NULL,
    [transactions] INT          NULL,
    [customers]    INT          NULL,
    [Spend]        MONEY        NULL,
    [fb]           INT          NULL,
    [type]         VARCHAR (15) NOT NULL
);

