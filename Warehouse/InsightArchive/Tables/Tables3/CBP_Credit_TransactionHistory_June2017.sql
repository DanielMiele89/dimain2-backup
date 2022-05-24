﻿CREATE TABLE [InsightArchive].[CBP_Credit_TransactionHistory_June2017] (
    [FileID]                                  INT           NOT NULL,
    [RowNum]                                  INT           NOT NULL,
    [DetailIdentifier]                        NVARCHAR (2)  NULL,
    [ClientProductCode]                       NVARCHAR (3)  NULL,
    [AccountId]                               NVARCHAR (11) NULL,
    [SuffixNumber]                            NVARCHAR (2)  NULL,
    [CurrentProcessingDate]                   NVARCHAR (7)  NULL,
    [TransactionCategory]                     NVARCHAR (4)  NULL,
    [OutputTransactionCodeInternal]           NVARCHAR (4)  NULL,
    [TransactionAmount]                       NVARCHAR (15) NULL,
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
    [ChargebackIndicator]                     CHAR (1)      NULL,
    [MailPhoneOrderIndicatorECIIndicatorVISA] CHAR (1)      NULL,
    [OriginalTransactionAmount]               NVARCHAR (14) NULL,
    [MerchantZip]                             NVARCHAR (9)  NULL,
    [TerminalEntry]                           NVARCHAR (2)  NULL,
    [TransactionSource]                       NVARCHAR (2)  NULL,
    [AccountingFunction]                      NVARCHAR (3)  NULL,
    [TransactionID]                           NVARCHAR (15) NULL,
    [CardAcceptorID]                          NVARCHAR (15) NULL,
    [ClassCode]                               NCHAR (2)     NULL,
    [DebitCreditIndicator]                    CHAR (1)      NULL,
    [CIN]                                     NVARCHAR (15) NULL,
    [CardholderPresentData]                   CHAR (1)      NULL,
    [CardholderPresentMC]                     CHAR (1)      NULL,
    [FraudTransactionStatus]                  CHAR (1)      NULL,
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
    [Amount]                                  SMALLMONEY    NULL,
    [TranDate]                                VARCHAR (10)  NULL,
    [IsValidTransactionDate]                  BIT           NULL,
    [IsMIDProcessed]                          BIT           NULL,
    [IsNonMIDProcessed]                       BIT           NULL,
    [IsValidTransaction]                      BIT           NULL
);


GO
CREATE NONCLUSTERED INDEX [cix_CBP_Credit_TransactionHistory_June2017_MerchantDBAName]
    ON [InsightArchive].[CBP_Credit_TransactionHistory_June2017]([MerchantDBAName] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [cix_CBP_Credit_TransactionHistory_June2017_TranDate]
    ON [InsightArchive].[CBP_Credit_TransactionHistory_June2017]([TranDate] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE CLUSTERED INDEX [cix_CBP_Credit_TransactionHistory_June2017_MerchantID]
    ON [InsightArchive].[CBP_Credit_TransactionHistory_June2017]([MerchantID] ASC) WITH (DATA_COMPRESSION = PAGE);

