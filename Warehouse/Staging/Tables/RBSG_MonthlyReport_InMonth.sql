﻿CREATE TABLE [Staging].[RBSG_MonthlyReport_InMonth] (
    [RedemptionMonth]           DATE          NULL,
    [CharityCount]              INT           NULL,
    [Charity_Pct]               FLOAT (53)    NULL,
    [CashCount]                 INT           NULL,
    [Cash_Pct]                  FLOAT (53)    NULL,
    [TradeUpCount]              INT           NULL,
    [TradeUp_Pct]               FLOAT (53)    NULL,
    [RedemptionCount]           INT           NULL,
    [TotalCashbackSpent]        MONEY         NULL,
    [UniqueRedeemers]           INT           NULL,
    [AVG_CharityCount]          INT           NULL,
    [AVG_Charity_Pct]           FLOAT (53)    NULL,
    [AVG_CashCount]             INT           NULL,
    [AVG_Cash_Pct]              FLOAT (53)    NULL,
    [AVG_TradeUpCount]          INT           NULL,
    [AVG_TradeUp_Pct]           FLOAT (53)    NULL,
    [AVG_RedemptionCount]       INT           NULL,
    [AVG_TotalCashbackSpent]    MONEY         NULL,
    [AVG_UniqueRedeemers]       INT           NULL,
    [CumulativeRedemptionCount] INT           NULL,
    [TranAddedMonth]            DATE          NULL,
    [Spend]                     MONEY         NULL,
    [CashbackEarned]            MONEY         NULL,
    [CountMembersSpent]         INT           NULL,
    [SpendTier1]                MONEY         NULL,
    [SpendTier1Pct]             MONEY         NULL,
    [SpendTier2]                MONEY         NULL,
    [SpendTier2Pct]             MONEY         NULL,
    [SpendTier3]                MONEY         NULL,
    [SpendTier3Pct]             MONEY         NULL,
    [Avg_Spend]                 MONEY         NULL,
    [Avg_CashbackEarned]        MONEY         NULL,
    [Avg_Count_Membes_Spent]    INT           NULL,
    [avg_SpendTier1]            MONEY         NULL,
    [avg_SpendTier2]            MONEY         NULL,
    [avg_SpendTier3]            MONEY         NULL,
    [CB_GBP15Plus_Customers]    INT           NULL,
    [Activations]               INT           NULL,
    [PartnerName1]              VARCHAR (100) NULL,
    [Spend1]                    MONEY         NULL,
    [PartnerName2]              VARCHAR (100) NULL,
    [Spend2]                    MONEY         NULL,
    [PartnerName3]              VARCHAR (100) NULL,
    [Spend3]                    MONEY         NULL,
    [PartnerName4]              VARCHAR (100) NULL,
    [Spend4]                    MONEY         NULL,
    [PartnerName5]              VARCHAR (100) NULL,
    [Spend5]                    MONEY         NULL,
    [PartnerName1_Cum]          VARCHAR (100) NULL,
    [Spend1_Cum]                MONEY         NULL,
    [PartnerName2_Cum]          VARCHAR (100) NULL,
    [Spend2_Cum]                MONEY         NULL,
    [PartnerName3_Cum]          VARCHAR (100) NULL,
    [Spend3_Cum]                MONEY         NULL,
    [PartnerName4_Cum]          VARCHAR (100) NULL,
    [Spend4_Cum]                MONEY         NULL,
    [PartnerName5_Cum]          VARCHAR (100) NULL,
    [Spend5_Cum]                MONEY         NULL,
    [MonthlySpend_20Pct]        MONEY         NULL,
    [MonthlyTrans_20Pct]        INT           NULL,
    [MonthlyEarned_20Pct]       MONEY         NULL,
    [MonthlySpend_40Pct]        MONEY         NULL,
    [MonthlyTrans_40Pct]        INT           NULL,
    [MonthlyEarned_40Pct]       MONEY         NULL,
    [Avg_MS_20Pct]              MONEY         NULL,
    [Avg_ME_20Pct]              MONEY         NULL,
    [Avg_MT_20Pct]              INT           NULL,
    [Avg_MS_40Pct]              MONEY         NULL,
    [Avg_ME_40Pct]              MONEY         NULL,
    [Avg_MT_40Pct]              INT           NULL,
    [WhichMonth]                VARCHAR (2)   NOT NULL,
    [AverageActivations]        REAL          NULL
);

