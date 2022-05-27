﻿CREATE TABLE [Report].[OfferReport_Metrics] (
    [ID]                      INT           IDENTITY (1, 1) NOT NULL,
    [PartnerID]               INT           NULL,
    [OfferID]                 INT           NOT NULL,
    [IronOfferID]             INT           NOT NULL,
    [OfferReportingPeriodsID] INT           NULL,
    [ControlGroupID]          INT           NOT NULL,
    [StartDate]               DATETIME2 (7) NULL,
    [EndDate]                 DATETIME2 (7) NULL,
    [Exposed]                 BIT           NOT NULL,
    [Channel]                 BIT           NULL,
    [Threshold]               BIT           NULL,
    [Sales]                   MONEY         NOT NULL,
    [Trans]                   FLOAT (53)    NOT NULL,
    [AllTransThreshold]       INT           NULL,
    [Spenders]                FLOAT (53)    NOT NULL,
    [Cardholders]             INT           NULL,
    [SPC]                     FLOAT (53)    NULL,
    [TPC]                     FLOAT (53)    NULL,
    [RR]                      FLOAT (53)    NULL,
    [ATV]                     FLOAT (53)    NULL,
    [ATF]                     FLOAT (53)    NULL,
    [SPS]                     FLOAT (53)    NULL,
    [AdjFactor_RR]            FLOAT (53)    NULL,
    [SPC_Uplift]              FLOAT (53)    NULL,
    [TPC_Uplift]              FLOAT (53)    NULL,
    [RR_Uplift]               FLOAT (53)    NULL,
    [IncSales]                FLOAT (53)    NULL,
    [IncTrans]                FLOAT (53)    NULL,
    CONSTRAINT [PK_MetricsID] PRIMARY KEY CLUSTERED ([ID] ASC)
);
