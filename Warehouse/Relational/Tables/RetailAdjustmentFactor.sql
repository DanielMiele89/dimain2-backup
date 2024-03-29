﻿CREATE TABLE [Relational].[RetailAdjustmentFactor] (
    [ID]                              INT              IDENTITY (1, 1) NOT NULL,
    [PartnerID]                       INT              NULL,
    [ActivatedCount]                  INT              NOT NULL,
    [ControlCount]                    INT              NOT NULL,
    [PrePeriodActivatedSales]         MONEY            NULL,
    [PrePeriodControlSales]           MONEY            NULL,
    [MonthID]                         INT              NOT NULL,
    [PartnerGroupID]                  INT              NULL,
    [ActivatedSpenders]               INT              NULL,
    [ControlSpenders]                 INT              NULL,
    [AdjFactor_TotalSPC]              DECIMAL (18, 16) NOT NULL,
    [AdjFactor_TotalRR]               DECIMAL (18, 16) NOT NULL,
    [AdjFactor_TotalSPS]              DECIMAL (18, 16) NOT NULL,
    [AdjFactor_TotalATV]              DECIMAL (18, 16) NOT NULL,
    [AdjFactor_TotalATF]              DECIMAL (18, 16) NOT NULL,
    [AdjFactor_OfflineSPC]            DECIMAL (18, 16) NULL,
    [AdjFactor_OnlineSPC]             DECIMAL (18, 16) NULL,
    [AdjFactor_BPCompanySPC]          DECIMAL (18, 16) NULL,
    [AdjFactor_BPDealerSPC]           DECIMAL (18, 16) NULL,
    [AdjFactor_TrainlineMobileAppSPC] DECIMAL (18, 16) NULL,
    [AdjFactor_TrainlineWebsiteSPC]   DECIMAL (18, 16) NULL,
    [AdjFactor_NewRR]                 DECIMAL (18, 16) NULL,
    [AdjFactor_NewSPC]                DECIMAL (18, 16) NULL,
    [AdjFactor_NewTPC]                DECIMAL (18, 16) NULL,
    [AdjFactor_LapsedRR]              DECIMAL (18, 16) NULL,
    [AdjFactor_LapsedSPC]             DECIMAL (18, 16) NULL,
    [AdjFactor_LapsedTPC]             DECIMAL (18, 16) NULL,
    [AdjFactor_ExistingRR]            DECIMAL (18, 16) NULL,
    [AdjFactor_ExistingSPC]           DECIMAL (18, 16) NULL,
    [AdjFactor_ExistingTPC]           DECIMAL (18, 16) NULL,
    [AdjFactor_Split1_Status1_SPC]    DECIMAL (18, 16) NULL,
    [AdjFactor_Split1_Status2_SPC]    DECIMAL (18, 16) NULL,
    [AdjFactor_Split1_Status3_SPC]    DECIMAL (18, 16) NULL,
    [AdjFactor_Split1_Status4_SPC]    DECIMAL (18, 16) NULL,
    [AdjFactor_Split1_Status5_SPC]    DECIMAL (18, 16) NULL,
    [AdjFactor_Split1_Status6_SPC]    DECIMAL (18, 16) NULL,
    [AdjFactor_Split2_Status1_SPC]    DECIMAL (18, 16) NULL,
    [AdjFactor_Split2_Status2_SPC]    DECIMAL (18, 16) NULL,
    [AdjFactor_Split2_Status3_SPC]    DECIMAL (18, 16) NULL,
    [AdjFactor_Split2_Status4_SPC]    DECIMAL (18, 16) NULL,
    [AdjFactor_Split2_Status5_SPC]    DECIMAL (18, 16) NULL,
    [AdjFactor_Split2_Status6_SPC]    DECIMAL (18, 16) NULL,
    [ClientServicesRef]               VARCHAR (40)     NULL,
    [AdjFactor_YTDNewRR]              DECIMAL (18, 16) NULL,
    [AdjFactor_YTDNewSPC]             DECIMAL (18, 16) NULL,
    [AdjFactor_YTDNewTPC]             DECIMAL (18, 16) NULL,
    [AdjFactor_YTDLapsedRR]           DECIMAL (18, 16) NULL,
    [AdjFactor_YTDLapsedSPC]          DECIMAL (18, 16) NULL,
    [AdjFactor_YTDLapsedTPC]          DECIMAL (18, 16) NULL,
    [AdjFactor_YTDExistingRR]         DECIMAL (18, 16) NULL,
    [AdjFactor_YTDExistingSPC]        DECIMAL (18, 16) NULL,
    [AdjFactor_YTDExistingTPC]        DECIMAL (18, 16) NULL,
    CONSTRAINT [PK_Relational_RetailAdjustmentFactor] PRIMARY KEY CLUSTERED ([ID] ASC)
);




GO
GRANT ALTER
    ON OBJECT::[Relational].[RetailAdjustmentFactor] TO [RetailerMonthlyReportUser]
    AS [dbo];

