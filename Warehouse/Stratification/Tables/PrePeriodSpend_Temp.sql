CREATE TABLE [Stratification].[PrePeriodSpend_Temp] (
    [ReportMonth]      INT        NOT NULL,
    [CINID]            INT        NULL,
    [FanID]            INT        NOT NULL,
    [Activated]        INT        NOT NULL,
    [IsRainbow]        INT        NOT NULL,
    [BigRetail_Spend]  MONEY      NOT NULL,
    [Grocery_Spend]    FLOAT (53) NOT NULL,
    [Coalition_Spend]  FLOAT (53) NOT NULL,
    [BigRetail_Txns]   FLOAT (53) NOT NULL,
    [Grocery_Txns]     FLOAT (53) NOT NULL,
    [Coalition_Txns]   FLOAT (53) NOT NULL,
    [Petrol_Spend]     FLOAT (53) NOT NULL,
    [BP_Spend]         FLOAT (53) NOT NULL,
    [Petrol_Txns]      FLOAT (53) NOT NULL,
    [BP_Txns]          FLOAT (53) NOT NULL,
    [BP_ShareofWallet] FLOAT (53) NULL,
    [LastRetailDate]   DATE       NULL,
    [Recency]          INT        NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

