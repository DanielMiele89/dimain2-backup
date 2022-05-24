CREATE TABLE [Stratification].[CBPCardUsageUplift_AdjustmentFactor_Total] (
    [MonthID]                 INT        NOT NULL,
    [ActivatedCount]          INT        NULL,
    [ControlCount]            INT        NULL,
    [ActivatedSpenders]       INT        NULL,
    [ControlSpenders]         INT        NULL,
    [PrePeriodActivatedSales] FLOAT (53) NULL,
    [PrePeriodControlSales]   FLOAT (53) NULL,
    [AdjFactor_TotalSPC]      FLOAT (53) NULL,
    [AdjFactor_TotalRR]       FLOAT (53) NULL,
    [AdjFactor_TotalSPS]      FLOAT (53) NULL,
    [AdjFactor_TotalATV]      FLOAT (53) NULL,
    [AdjFactor_TotalATF]      FLOAT (53) NULL
);

