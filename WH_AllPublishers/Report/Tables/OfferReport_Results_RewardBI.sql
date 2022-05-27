﻿CREATE TABLE [Report].[OfferReport_Results_RewardBI] (
    [ID]                   INT        NOT NULL,
    [IronOfferID]          INT        NULL,
    [IronOfferCyclesID]    INT        NULL,
    [ControlGroupTypeID]   INT        NOT NULL,
    [StartDate]            DATE       NULL,
    [EndDate]              DATE       NULL,
    [Channel]              BIT        NULL,
    [Threshold]            BIT        NULL,
    [Cardholders_E]        INT        NULL,
    [Sales_E]              MONEY      NULL,
    [Spenders_E]           INT        NULL,
    [Transactions_E]       INT        NULL,
    [IncentivisedSales]    MONEY      NULL,
    [IncentivisedTrans]    INT        NULL,
    [Cardholders_C]        INT        NULL,
    [Spenders_C]           INT        NULL,
    [Transactions_C]       INT        NULL,
    [RR_C]                 REAL       NULL,
    [SPC_C]                REAL       NULL,
    [TPC_C]                REAL       NULL,
    [ATV_C]                REAL       NULL,
    [ATF_C]                REAL       NULL,
    [SPS_C]                REAL       NULL,
    [AdjFactor_RR]         FLOAT (53) NULL,
    [IncSales]             REAL       NULL,
    [IncTransactions]      REAL       NULL,
    [MonthlyReportingDate] DATE       NULL,
    [isPartial]            BIT        NULL,
    [offerStartDate]       DATE       NULL,
    [offerEndDate]         DATE       NULL,
    [PartnerID]            INT        NULL,
    [ClubID]               INT        NULL,
    [IncentivisedSpenders] INT        NULL,
    [AllTransThreshold]    INT        NULL,
    [Sales_C]              MONEY      NULL,
    [PreAdjTrans]          INT        NULL,
    [PreAdjSpenders]       INT        NULL,
    [AllTransThreshold_E]  INT        NULL,
    [AllTransThreshold_C]  INT        NULL
);


GO
CREATE CLUSTERED INDEX [CIX_IronOfferID]
    ON [Report].[OfferReport_Results_RewardBI]([IronOfferID] ASC);

