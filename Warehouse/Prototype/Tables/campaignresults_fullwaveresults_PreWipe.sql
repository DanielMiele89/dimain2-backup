﻿CREATE TABLE [Prototype].[campaignresults_fullwaveresults_PreWipe] (
    [ID]                      INT           IDENTITY (1, 1) NOT NULL,
    [IronOfferID]             INT           NULL,
    [ClientServicesRef]       NVARCHAR (30) NULL,
    [StartDate]               DATE          NULL,
    [EndDate]                 DATE          NULL,
    [SplitName]               NVARCHAR (50) NULL,
    [Universe]                NVARCHAR (30) NULL,
    [CashbackRate]            INT           NULL,
    [SpendStretch]            INT           NULL,
    [Cardholders]             INT           NULL,
    [Spenders]                INT           NULL,
    [TotalSales]              MONEY         NULL,
    [IncrementalSales]        REAL          NULL,
    [Transactions]            INT           NULL,
    [IncrementalSpenders]     REAL          NULL,
    [IncrementalTransactions] REAL          NULL,
    [CampaignCost]            MONEY         NULL,
    [PValueSPC]               REAL          NULL,
    [Uplift]                  REAL          NULL,
    [ATVUplift]               REAL          NULL,
    [ATFUplift]               REAL          NULL,
    [SpenderUplift]           REAL          NULL,
    [TotalPValue]             REAL          NULL
);
