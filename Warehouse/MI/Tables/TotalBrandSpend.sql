CREATE TABLE [MI].[TotalBrandSpend] (
    [BrandID]                              SMALLINT NOT NULL,
    [SpendThisYear]                        MONEY    NOT NULL,
    [TranCountThisYear]                    INT      NOT NULL,
    [CustomerCountThisYear]                INT      NOT NULL,
    [OnlineSpendThisYear]                  MONEY    NOT NULL,
    [OnlineTranCountThisYear]              INT      NOT NULL,
    [OnlineCustomerCountThisYear]          INT      NOT NULL,
    [SectorExclusiveCustomerCountThisYear] INT      NOT NULL,
    [SpendLastYear]                        MONEY    NOT NULL,
    [TranCountLastYear]                    INT      NOT NULL,
    [CustomerCountLastYear]                INT      NOT NULL,
    [OnlineSpendLastYear]                  MONEY    NOT NULL,
    [OnlineTranCountLastYear]              INT      NOT NULL,
    [OnlineCustomerCountLastYear]          INT      NOT NULL,
    [SectorExclusiveCustomerCountLastYear] INT      NOT NULL,
    CONSTRAINT [PK_MI_TotalBrandSpend] PRIMARY KEY CLUSTERED ([BrandID] ASC)
);

