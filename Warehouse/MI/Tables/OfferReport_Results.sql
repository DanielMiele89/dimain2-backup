﻿CREATE TABLE [MI].[OfferReport_Results] (
    [ID]                   INT   IDENTITY (1, 1) NOT NULL,
    [IronOfferID]          INT   NOT NULL,
    [StartDate]            DATE  NOT NULL,
    [EndDate]              DATE  NOT NULL,
    [Channel]              BIT   NOT NULL,
    [Cardholders_E]        INT   NOT NULL,
    [Sales_E]              MONEY NOT NULL,
    [Spenders_E]           INT   NOT NULL,
    [Transactions_E]       INT   NOT NULL,
    [Cardholders_C]        INT   NOT NULL,
    [Spenders_C]           INT   NOT NULL,
    [Transactions_C]       INT   NOT NULL,
    [RR_C]                 REAL  NOT NULL,
    [SPC_C]                REAL  NOT NULL,
    [TPC_C]                REAL  NOT NULL,
    [ATV_C]                REAL  NOT NULL,
    [ATF_C]                REAL  NOT NULL,
    [SPS_C]                REAL  NOT NULL,
    [AdjFactor_RR]         INT   NOT NULL,
    [IncSales]             REAL  NOT NULL,
    [IncSpenders]          REAL  NOT NULL,
    [IncTransactions]      REAL  NOT NULL,
    [MonthlyReportingDate] DATE  NOT NULL,
    [isPartial]            BIT   NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);
