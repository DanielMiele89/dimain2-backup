CREATE TABLE [Staging].[MissingAdditionalCashbackAwards_OLD] (
    [TransactionID]                          INT           NOT NULL,
    [SourceSystemID]                         INT           NOT NULL,
    [SourceID]                               INT           NOT NULL,
    [SourceTypeID]                           INT           NOT NULL,
    [FanID]                                  INT           NOT NULL,
    [IronOfferID]                            INT           NOT NULL,
    [PartnerID]                              INT           NOT NULL,
    [PublisherID]                            SMALLINT      NOT NULL,
    [Spend]                                  SMALLMONEY    NULL,
    [Earnings]                               SMALLMONEY    NULL,
    [TranDate]                               DATE          NOT NULL,
    [TransactionTypeID]                      SMALLINT      NOT NULL,
    [AdditionalCashbackAwardTypeID]          SMALLINT      NOT NULL,
    [AdditionalCashbackAdjustmentTypeID]     SMALLINT      NOT NULL,
    [AdditionalCashbackAdjustmentCategoryID] SMALLINT      NOT NULL,
    [PaymentMethodID]                        SMALLINT      NOT NULL,
    [DirectDebitOriginatorID]                INT           NULL,
    [EarningSourceID]                        SMALLINT      NULL,
    [SourceAddedDate]                        DATE          NULL,
    [CreatedDateTime]                        DATETIME2 (7) NOT NULL,
    [ActivationDays]                         INT           NULL
);

