CREATE TABLE [Staging].[SLC_Report_FirstSpendDD_Retro] (
    [FanID]           INT          NOT NULL,
    [FirstEarnValue]  SMALLMONEY   NULL,
    [FirstEarndate]   DATE         NULL,
    [MyRewardAccount] VARCHAR (30) NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

