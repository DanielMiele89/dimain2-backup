﻿CREATE TABLE [Report].[OfferReport_ReportData_Monthly] (
    [ID]                         INT          IDENTITY (1, 1) NOT NULL,
    [OfferID]                    INT          NULL,
    [OfferName]                  VARCHAR (50) NULL,
    [ControlGroupTypeID]         INT          NOT NULL,
    [StartDate]                  DATE         NULL,
    [EndDate]                    DATE         NULL,
    [MonthlyDate]                DATE         NULL,
    [PartnerID]                  INT          NULL,
    [CashbackRate]               INT          NULL,
    [SpendStretch]               SMALLMONEY   NULL,
    [SuperSegmentID]             SMALLINT     NULL,
    [Channel]                    BIT          NULL,
    [Threshold]                  BIT          NULL,
    [Cardholders]                INT          NULL,
    [ControlGroupSize]           INT          NULL,
    [Spenders]                   INT          NULL,
    [IncSpenders]                REAL         NULL,
    [Trans]                      INT          NULL,
    [IncTrans]                   REAL         NULL,
    [Sales]                      MONEY        NULL,
    [IncSales]                   REAL         NULL,
    [Investment]                 MONEY        NULL,
    [StatisticalSignificance]    VARCHAR (10) NULL,
    [StatisticalSignificance_SS] VARCHAR (10) NULL,
    [OverallSpenders]            INT          NULL,
    [Uplift]                     REAL         NULL,
    [SpendersUplift]             REAL         NULL,
    [ATVUplift]                  REAL         NULL,
    [ATFUplift]                  REAL         NULL,
    [AllTransThreshold]          INT          NULL,
    [Sales_E]                    MONEY        NULL,
    [Trans_E]                    INT          NULL,
    [Spenders_E]                 INT          NULL,
    [Sales_C]                    MONEY        NULL,
    [Trans_C]                    INT          NULL,
    [Spenders_C]                 INT          NULL,
    [PreAdjSpenders_C]           INT          NULL,
    [AllTransThreshold_E]        INT          NULL,
    [AllTransThreshold_C]        INT          NULL,
    [PreAdjTrans_C]              INT          NULL,
    CONSTRAINT [PK_ReportDataMonthlyID] PRIMARY KEY CLUSTERED ([ID] ASC)
);
