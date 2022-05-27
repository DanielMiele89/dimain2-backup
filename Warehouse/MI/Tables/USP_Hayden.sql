﻿CREATE TABLE [MI].[USP_Hayden] (
    [ID]                         INT              IDENTITY (1, 1) NOT NULL,
    [StatsDate]                  DATE             NOT NULL,
    [TotalTransactions]          BIGINT           NOT NULL,
    [TotalTransactionsLastYear]  BIGINT           NOT NULL,
    [TotalTransactionsLastMonth] BIGINT           NOT NULL,
    [SchemeActivations]          INT              NOT NULL,
    [EarningsTotal]              MONEY            NOT NULL,
    [SectorCount]                TINYINT          NOT NULL,
    [BrandCount]                 SMALLINT         NOT NULL,
    [CardholderCount]            INT              NOT NULL,
    [AverageUpliftMonth]         MONEY            NOT NULL,
    [AverageUpliftLaunch]        DECIMAL (18, 16) NOT NULL,
    [IncrementalSalesTotal]      MONEY            NOT NULL,
    [TopSalesROI]                MONEY            NOT NULL,
    [TopFinancialROI]            MONEY            NOT NULL,
    [MaleCount]                  INT              NOT NULL,
    [FemaleCount]                INT              NOT NULL,
    [UpliftedSalesTotal]         MONEY            NOT NULL,
    [AverageSalesROIMonth]       MONEY            NOT NULL,
    [AverageSalesROILaunch]      MONEY            NOT NULL,
    [CBPActiveCustomers]         INT              NOT NULL,
    [SpendTotal]                 MONEY            DEFAULT ((0)) NOT NULL,
    [PublisherName]              VARCHAR (50)     DEFAULT ('~') NOT NULL,
    CONSTRAINT [PK_MI_USPHayden] PRIMARY KEY CLUSTERED ([ID] ASC)
);
