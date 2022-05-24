CREATE TABLE [Stratification].[BrandRainbow_Scalars] (
    [BrandID]                     SMALLINT   NOT NULL,
    [PartnerID]                   INT        NULL,
    [Total_Spend]                 MONEY      NOT NULL,
    [RainbowPeriod_Spend]         MONEY      NOT NULL,
    [OverallRainbow_SpendScalar]  FLOAT (53) NULL,
    [PersonalRainbow_SpendScalar] FLOAT (53) NULL,
    [Total_Txns]                  INT        NOT NULL,
    [RainbowPeriod_Txns]          INT        NOT NULL,
    [OverallRainbow_TxnsScalar]   FLOAT (53) NULL,
    [PersonalRainbow_TxnsScalar]  FLOAT (53) NULL
);


GO
CREATE NONCLUSTERED INDEX [PartnerIDndex]
    ON [Stratification].[BrandRainbow_Scalars]([PartnerID] ASC);


GO
CREATE CLUSTERED INDEX [BrandIDndex]
    ON [Stratification].[BrandRainbow_Scalars]([BrandID] ASC);

