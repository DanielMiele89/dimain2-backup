CREATE TABLE [Prototype].[ROCP2_RBS_MyRewardsBase] (
    [FanID]             INT           NOT NULL,
    [CINID]             INT           NOT NULL,
    [Gender]            CHAR (1)      NULL,
    [Age_Group]         VARCHAR (12)  NULL,
    [CAMEO_CODE_GRP]    VARCHAR (151) NOT NULL,
    [Region]            VARCHAR (30)  NULL,
    [MarketableByEmail] BIT           NULL
);


GO
CREATE NONCLUSTERED INDEX [IND_C]
    ON [Prototype].[ROCP2_RBS_MyRewardsBase]([CINID] ASC);

