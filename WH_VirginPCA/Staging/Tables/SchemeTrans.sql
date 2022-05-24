﻿CREATE TABLE [Staging].[SchemeTrans] (
    [ID]                      INT              NOT NULL,
    [SchemeTransID]           INT              NOT NULL,
    [Spend]                   MONEY            NOT NULL,
    [RetailerCashback]        MONEY            NOT NULL,
    [TranDate]                DATE             NOT NULL,
    [AddedDate]               DATE             NOT NULL,
    [FanID]                   INT              NOT NULL,
    [RetailerID]              INT              NOT NULL,
    [PublisherID]             INT              NOT NULL,
    [PublisherCommission]     MONEY            NOT NULL,
    [RewardCommission]        SMALLMONEY       NOT NULL,
    [TranFixDate]             DATE             NULL,
    [IsNegative]              BIT              NOT NULL,
    [Investment]              MONEY            NOT NULL,
    [IsOnline]                BIT              NOT NULL,
    [IsRetailMonthly]         BIT              NOT NULL,
    [NotRewardManaged]        BIT              NOT NULL,
    [SpendStretchAmount]      MONEY            NULL,
    [IsSpendStretch]          BIT              NULL,
    [IronOfferID]             INT              NULL,
    [OutletID]                INT              NULL,
    [DirectDebitOriginatorID] INT              NULL,
    [PanID]                   INT              NULL,
    [SubPublisherID]          TINYINT          NOT NULL,
    [IsRetailerReport]        BIT              NOT NULL,
    [OfferPercentage]         FLOAT (53)       NOT NULL,
    [CommissionRate]          FLOAT (53)       NOT NULL,
    [VATCommission]           MONEY            NOT NULL,
    [GrossCommission]         MONEY            NOT NULL,
    [TranTime]                TIME (7)         NOT NULL,
    [Imported]                BIT              NOT NULL,
    [MaskedCardNumber]        VARCHAR (20)     NULL,
    [TransactionGUID]         UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_BI_SchemeTrans] PRIMARY KEY CLUSTERED ([ID] ASC)
);
