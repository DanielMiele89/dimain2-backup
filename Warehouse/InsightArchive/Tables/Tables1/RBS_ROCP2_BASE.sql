CREATE TABLE [InsightArchive].[RBS_ROCP2_BASE] (
    [fANID]             INT           NOT NULL,
    [CINID]             INT           NOT NULL,
    [Gender]            CHAR (1)      NULL,
    [Age_Group]         VARCHAR (12)  NULL,
    [CAMEO_CODE_GRP]    VARCHAR (151) NOT NULL,
    [Region]            VARCHAR (30)  NULL,
    [MarketableByEmail] BIT           NULL
);


GO
CREATE NONCLUSTERED INDEX [IND_Cins]
    ON [InsightArchive].[RBS_ROCP2_BASE]([CINID] ASC);

