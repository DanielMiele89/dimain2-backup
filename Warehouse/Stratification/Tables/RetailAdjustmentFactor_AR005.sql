﻿CREATE TABLE [Stratification].[RetailAdjustmentFactor_AR005] (
    [PartnerID]               INT        NULL,
    [ActivatedCount]          INT        NULL,
    [ControlCount]            INT        NULL,
    [PrePeriodActivatedSales] FLOAT (53) NULL,
    [PrePeriodControlSales]   FLOAT (53) NULL,
    [MonthID]                 INT        NULL,
    [PartnerGroupID]          INT        NULL,
    [ActivatedSpenders]       INT        NULL,
    [ControlSpenders]         INT        NULL,
    [AdjFactor_TotalSPC]      FLOAT (53) NULL,
    [AdjFactor_TotalRR]       FLOAT (53) NULL,
    [AdjFactor_TotalSPS]      FLOAT (53) NULL,
    [AdjFactor_TotalATV]      FLOAT (53) NULL,
    [AdjFactor_TotalATF]      FLOAT (53) NULL,
    [AdjFactor_OfflineSPC]    FLOAT (53) NULL,
    [AdjFactor_OnlineSPC]     FLOAT (53) NULL,
    [AdjFactor_BPCompanySPC]  FLOAT (53) NULL,
    [AdjFactor_BPDealerSPC]   FLOAT (53) NULL,
    [AdjFactor_ExistingSPC]   FLOAT (53) NULL,
    [AdjFactor_ExistingRR]    FLOAT (53) NULL,
    [AdjFactor_NewSPC]        FLOAT (53) NULL,
    [AdjFactor_NewRR]         FLOAT (53) NULL
);

