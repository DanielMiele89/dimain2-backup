﻿CREATE TABLE [Staging].[Derived_PartnerTrans_20211008] (
    [ID]                              INT              IDENTITY (1, 1) NOT NULL,
    [FileID]                          INT              NOT NULL,
    [RowNum]                          INT              NOT NULL,
    [FanID]                           INT              NOT NULL,
    [PartnerID]                       INT              NULL,
    [OutletID]                        INT              NULL,
    [IsOnline]                        BIT              NULL,
    [CardHolderPresentData]           CHAR (1)         NULL,
    [TransactionAmount]               SMALLMONEY       NOT NULL,
    [ExtremeValueFlag]                BIT              NULL,
    [TransactionDate]                 DATE             NULL,
    [TransactionWeekStarting]         DATE             NULL,
    [TransactionMonth]                TINYINT          NULL,
    [TransactionYear]                 SMALLINT         NULL,
    [TransactionWeekStartingCampaign] DATE             NULL,
    [AddedDate]                       DATE             NULL,
    [AddedWeekStarting]               DATE             NULL,
    [AddedMonth]                      TINYINT          NULL,
    [AddedYear]                       SMALLINT         NULL,
    [AffiliateCommissionAmount]       SMALLMONEY       NULL,
    [CommissionChargable]             MONEY            NULL,
    [CashbackEarned]                  MONEY            NULL,
    [IronOfferID]                     INT              NULL,
    [ActivationDays]                  INT              NULL,
    [AboveBase]                       INT              NULL,
    [PaymentMethodID]                 TINYINT          NULL,
    [UniqueTransactionID]             UNIQUEIDENTIFIER NULL
);

