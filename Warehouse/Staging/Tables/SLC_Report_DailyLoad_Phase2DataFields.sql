CREATE TABLE [Staging].[SLC_Report_DailyLoad_Phase2DataFields] (
    [FanID]            INT           NOT NULL,
    [LoyaltyAccount]   BIT           NOT NULL,
    [IsLoyalty]        BIT           NULL,
    [WG]               BIT           NULL,
    [FirstEarnDate]    DATE          NULL,
    [FirstEarnType]    VARCHAR (100) NULL,
    [FirstEarnValue]   SMALLMONEY    NULL,
    [Reached5GBP]      DATE          NULL,
    [Day65AccountName] VARCHAR (40)  NULL,
    [Day65AccountNo]   VARCHAR (3)   NULL,
    [Homemover]        BIT           NULL,
    [MyRewardAccount]  VARCHAR (40)  NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC) WITH (FILLFACTOR = 80)
);

