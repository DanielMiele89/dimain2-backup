CREATE TABLE [InsightArchive].[Test_InprogrammeControlV1] (
    [FanID]             INT           NOT NULL,
    [cinid]             INT           NOT NULL,
    [Gender]            CHAR (1)      NULL,
    [AgeCategory]       VARCHAR (12)  NULL,
    [CameoCode]         VARCHAR (151) NOT NULL,
    [Region]            VARCHAR (30)  NULL,
    [MarketableByEmail] BIT           NULL,
    [HMcomboID]         INT           NULL,
    [HMscore]           INT           NULL,
    [SpendCat]          VARCHAR (50)  NULL,
    [Sales]             INT           NULL,
    [Txs]               INT           NULL,
    [Selection]         VARCHAR (20)  NULL,
    [DT]                FLOAT (53)    NULL,
    [postalsector]      VARCHAR (20)  NULL
);


GO
CREATE NONCLUSTERED INDEX [cix_Test_InprogrammeControlV1_SpendCat]
    ON [InsightArchive].[Test_InprogrammeControlV1]([SpendCat] ASC)
    INCLUDE([cinid]);


GO
CREATE CLUSTERED INDEX [C_INX]
    ON [InsightArchive].[Test_InprogrammeControlV1]([cinid] ASC);

