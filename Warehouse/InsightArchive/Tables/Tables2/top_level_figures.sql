CREATE TABLE [InsightArchive].[top_level_figures] (
    [BrandName]    VARCHAR (50) NOT NULL,
    [IsOnline]     BIT          NOT NULL,
    [transactions] INT          NULL,
    [customers]    INT          NULL,
    [Spend]        MONEY        NULL,
    [fb]           INT          NULL,
    [type]         VARCHAR (15) NOT NULL
);

