CREATE TABLE [InsightArchive].[CoffeeCustomers] (
    [FanID]                   INT   NOT NULL,
    [cinid]                   INT   NOT NULL,
    [RedemptionCount]         INT   NULL,
    [MyRewardsBalance]        MONEY NULL,
    [CoffeeVisits]            INT   NULL,
    [CaffeNeroVisits]         INT   NULL,
    [CoffeeVisitsFourMonths]  INT   NULL,
    [CoffeeSpendFourMonths]   MONEY NULL,
    [RedemptionCountTwoYears] INT   NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

