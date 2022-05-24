CREATE TABLE [InsightArchive].[PrePeriodSpend_Quidco_Control] (
    [Segment]                     VARCHAR (13) NOT NULL,
    [CINID]                       INT          NOT NULL,
    [Quidco_Join_Date]            DATE         NULL,
    [BigRetail_Spend]             MONEY        NOT NULL,
    [BigRetail_Txns]              INT          NOT NULL,
    [IsCoalition_Cineworld_Spend] MONEY        NOT NULL,
    [IsCoalition_Cineworld_Txns]  INT          NOT NULL,
    [IsCoalition_Debenhams_Spend] MONEY        NOT NULL,
    [IsCoalition_Debenhams_Txns]  INT          NOT NULL,
    [IsCoalition_Halfords_Spend]  MONEY        NOT NULL,
    [IsCoalition_Halfords_Txns]   INT          NOT NULL,
    [IsCoalition_CaffeNero_Spend] MONEY        NOT NULL,
    [IsCoalition_CaffeNero_Txns]  INT          NOT NULL,
    [Entertainment_Spend]         MONEY        NOT NULL,
    [Entertainment_Txns]          INT          NOT NULL,
    [Department_Spend]            MONEY        NOT NULL,
    [Department_Txns]             INT          NOT NULL,
    [Vehicles_Spend]              MONEY        NOT NULL,
    [Vehicles_Txns]               INT          NOT NULL,
    [Clothing_Spend]              MONEY        NOT NULL,
    [Clothing_Txns]               INT          NOT NULL,
    [RestaurantBars_Spend]        MONEY        NOT NULL,
    [RestaurantBars_Txns]         INT          NOT NULL
);


GO
CREATE CLUSTERED INDEX [CINIDINDEX]
    ON [InsightArchive].[PrePeriodSpend_Quidco_Control]([CINID] ASC);

