CREATE TABLE [InsightArchive].[KantarDisAggData] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [GroupType] VARCHAR (20) NULL,
    [Segment]   VARCHAR (20) NULL,
    [CINID]     INT          NULL,
    [BrandID]   SMALLINT     NULL,
    [Amount]    MONEY        NULL,
    [TranDate]  DATE         NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

