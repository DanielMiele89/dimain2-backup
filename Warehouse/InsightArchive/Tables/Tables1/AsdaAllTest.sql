﻿CREATE TABLE [InsightArchive].[AsdaAllTest] (
    [FileID]                                  INT           NOT NULL,
    [RowNum]                                  INT           NOT NULL,
    [DetailIdentifier]                        NVARCHAR (2)  NULL,
    [ClientProductCode]                       NVARCHAR (3)  NULL,
    [AccountId]                               NVARCHAR (11) NULL,
    [SuffixNumber]                            NVARCHAR (2)  NULL,
    [CurrentProcessingDate]                   NVARCHAR (7)  NULL,
    [TransactionCategory]                     NVARCHAR (4)  NULL,
    [OutputTransactionCodeInternal]           NVARCHAR (4)  NULL,
    [TransactionAmount]                       MONEY         NULL,
    [TransactionReferenceNumber]              NVARCHAR (23) NULL,
    [PostingDateOfTransaction]                NVARCHAR (7)  NULL,
    [TransactionDate]                         NVARCHAR (7)  NULL,
    [MerchantDBACountry]                      NVARCHAR (3)  NULL,
    [MerchantID]                              NVARCHAR (15) NULL,
    [MerchantAccountNumber]                   NVARCHAR (16) NULL,
    [MerchantDBAName]                         NVARCHAR (25) NULL,
    [MerchantDBACity]                         NVARCHAR (13) NULL,
    [MerchantDBAState]                        NVARCHAR (3)  NULL,
    [MerchantSICClassCode]                    NVARCHAR (4)  NULL,
    [CurrencyCode]                            NVARCHAR (3)  NULL,
    [ConversionRate]                          NVARCHAR (18) NULL,
    [ConversionDate]                          NVARCHAR (4)  NULL,
    [ChargebackIndicator]                     VARCHAR (1)   NULL,
    [MailPhoneOrderIndicatorECIIndicatorVISA] VARCHAR (1)   NULL,
    [OriginalTransactionAmount]               NVARCHAR (14) NULL,
    [MerchantZip]                             NVARCHAR (9)  NULL,
    [TerminalEntry]                           NVARCHAR (2)  NULL,
    [TransactionSource]                       NVARCHAR (2)  NULL,
    [AccountingFunction]                      NVARCHAR (3)  NULL,
    [TransactionID]                           NVARCHAR (15) NULL,
    [CardAcceptorID]                          NVARCHAR (15) NULL,
    [ClassCode]                               NVARCHAR (2)  NULL,
    [DebitCreditIndicator]                    VARCHAR (1)   NULL,
    [CIN]                                     NVARCHAR (15) NULL,
    [CardholderPresentData]                   VARCHAR (1)   NULL,
    [CardholderPresentMC]                     VARCHAR (1)   NULL,
    [FraudTransactionStatus]                  VARCHAR (1)   NULL,
    [InterchangeQualification]                NVARCHAR (2)  NULL,
    [ConversionMarkupRate]                    NVARCHAR (19) NULL,
    [PaymentCardID]                           INT           NULL,
    [PanID]                                   INT           NULL,
    [RetailOutletID]                          INT           NULL,
    [IronOfferMemberID]                       INT           NULL,
    [MatchID]                                 INT           NULL,
    [BillingRuleID]                           INT           NULL,
    [MarketingRuleID]                         INT           NULL,
    [CompositeID]                             BIGINT        NULL,
    [FanID]                                   INT           NULL,
    [ClubID]                                  INT           NULL,
    [MatchStatus]                             TINYINT       NULL,
    [RewardStatus]                            TINYINT       NULL,
    [Amount]                                  MONEY         NULL,
    [TranDate]                                DATE          NULL,
    [IsValidTransactionDate]                  BIT           NULL,
    [IsMIDProcessed]                          BIT           NULL,
    [IsNonMIDProcessed]                       BIT           NULL,
    [IsValidTransaction]                      BIT           NULL,
    CONSTRAINT [PK_InsightArchive_AsdaAllTest] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);

