CREATE TABLE [InsightArchive].[STOSalesForecast_FixedBase] (
    [fANID]          INT           NOT NULL,
    [CINID]          INT           NOT NULL,
    [Gender]         CHAR (1)      NULL,
    [Age_Group]      VARCHAR (12)  NULL,
    [CAMEO_CODE_GRP] VARCHAR (151) NOT NULL,
    [Region]         VARCHAR (30)  NULL
);


GO
CREATE CLUSTERED INDEX [IND_Cins]
    ON [InsightArchive].[STOSalesForecast_FixedBase]([CINID] ASC);

