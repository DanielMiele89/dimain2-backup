﻿CREATE TABLE [MI].[RetailerReportMonthly_OLD] (
    [ID]                            INT              IDENTITY (1, 1) NOT NULL,
    [MonthID]                       INT              NOT NULL,
    [LabelID]                       SMALLINT         NOT NULL,
    [PartnerID]                     INT              NULL,
    [PartnerGroupID]                INT              NULL,
    [ActivatedCardholders]          INT              NOT NULL,
    [ActivatedSpender]              INT              NOT NULL,
    [ControlCardholder]             INT              NOT NULL,
    [ControlSpender]                INT              NOT NULL,
    [AdjFactorSPC]                  DECIMAL (18, 16) NOT NULL,
    [AdjFactorRR]                   DECIMAL (18, 16) NOT NULL,
    [AdjFactorSPS]                  DECIMAL (18, 16) NOT NULL,
    [AdjFactorATV]                  DECIMAL (18, 16) NOT NULL,
    [AdjFactorATF]                  DECIMAL (18, 16) NOT NULL,
    [Label]                         VARCHAR (50)     NOT NULL,
    [MonthlyAVG]                    DECIMAL (18, 16) NULL,
    [MonthlySTDEV]                  DECIMAL (18, 16) NULL,
    [ActivatedTrans]                INT              NULL,
    [ActivatedSales]                MONEY            NULL,
    [IncrementalSales]              MONEY            NULL,
    [PostActivatedSales]            MONEY            NULL,
    [PostActivatedTrans]            INT              NULL,
    [ControlCardholderSales]        MONEY            NULL,
    [PostActivatedSpender]          INT              NULL,
    [ControlTrans]                  INT              NULL,
    [IncrementalTrans]              FLOAT (53)       NULL,
    [IncrementalSpenders]           FLOAT (53)       NULL,
    [FP_ActivatedCardholders]       INT              NULL,
    [FP_ActivatedSpender]           INT              NULL,
    [FP_ControlCardholders]         INT              NULL,
    [FP_ControlSpender]             INT              NULL,
    [CumulativeIncrementalSpenders] FLOAT (53)       NULL,
    [IronOfferID]                   INT              NULL,
    [ClientServicesRef]             VARCHAR (50)     NULL,
    [AdjFactorTPC]                  DECIMAL (18, 16) NULL,
    [Commission]                    MONEY            NULL,
    CONSTRAINT [PK_MI_RetailerReportMonthly] PRIMARY KEY CLUSTERED ([ID] ASC)
);
