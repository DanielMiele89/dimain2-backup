CREATE TABLE [Stratification].[PartnerAdjFactors_Cohort] (
    [PartnerGroupID]          INT          NULL,
    [PartnerID]               INT          NULL,
    [cohort]                  VARCHAR (50) NOT NULL,
    [MonthID]                 INT          NULL,
    [ActivatedCount]          INT          NULL,
    [ControlCount]            INT          NULL,
    [ActivatedSpenders]       INT          NULL,
    [ControlSpenders]         INT          NULL,
    [PrePeriodActivatedSales] FLOAT (53)   NULL,
    [PrePeriodControlSales]   FLOAT (53)   NULL,
    [AdjFactor_TotalSPC]      FLOAT (53)   NULL
);

