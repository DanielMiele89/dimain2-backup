CREATE TABLE [InsightArchive].[DDForecastStaging_FirstTranTotals] (
    [ID]                                        INT        IDENTITY (1, 1) NOT NULL,
    [ForecastID]                                INT        NOT NULL,
    [ForecastDate]                              DATETIME   NOT NULL,
    [Date]                                      DATE       NOT NULL,
    [Weighted_Shoppers_Household]               FLOAT (53) NULL,
    [Weighted_RewardEligibleShoppers_Household] FLOAT (53) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCIX_DDForecastStaging_FirstTranTotals]
    ON [InsightArchive].[DDForecastStaging_FirstTranTotals]([ForecastID] ASC);

