﻿CREATE TABLE [Inbound].[RBS_PartnerTrans] (
    [ID]                              INT             NOT NULL,
    [FanID]                           INT             NOT NULL,
    [PartnerID]                       INT             NULL,
    [OutletID]                        INT             NULL,
    [IsOnline]                        BIT             NULL,
    [CardHolderPresentData]           CHAR (1)        NULL,
    [TransactionAmount]               SMALLMONEY      NOT NULL,
    [ExtremeValueFlag]                BIT             NULL,
    [TransactionDate]                 DATE            NULL,
    [TransactionWeekStarting]         DATE            NULL,
    [TransactionMonth]                TINYINT         NULL,
    [TransactionYear]                 SMALLINT        NULL,
    [TransactionWeekStartingCampaign] DATE            NULL,
    [AddedDate]                       DATE            NULL,
    [AddedWeekStarting]               DATE            NULL,
    [AddedMonth]                      TINYINT         NULL,
    [AddedYear]                       SMALLINT        NULL,
    [AffiliateCommissionAmount]       DECIMAL (18, 2) NULL,
    [CommissionChargable]             DECIMAL (18, 2) NULL,
    [CashbackEarned]                  DECIMAL (18, 2) NULL,
    [EligibleForCashBack]             BIT             NULL,
    [IronOfferID]                     INT             NULL,
    [ActivationDays]                  INT             NULL,
    [AboveBase]                       INT             NULL,
    [PaymentMethodID]                 TINYINT         NULL
);

