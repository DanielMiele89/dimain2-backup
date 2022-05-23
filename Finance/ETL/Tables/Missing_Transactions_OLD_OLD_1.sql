CREATE TABLE [ETL].[Missing_Transactions_OLD_OLD] (
    [SourceSystemID]                         INT            NOT NULL,
    [SourceID]                               INT            NOT NULL,
    [SourceTypeID]                           INT            NOT NULL,
    [FanID]                                  INT            NOT NULL,
    [IronOfferID]                            INT            NOT NULL,
    [PartnerID]                              INT            NOT NULL,
    [PublisherID]                            INT            NOT NULL,
    [Spend]                                  SMALLMONEY     NULL,
    [Earnings]                               SMALLMONEY     NULL,
    [TranDate]                               DATE           NOT NULL,
    [TransactionTypeID]                      SMALLINT       NOT NULL,
    [AdditionalCashbackAwardTypeID]          SMALLINT       NOT NULL,
    [AdditionalCashbackAdjustmentTypeID]     SMALLINT       NOT NULL,
    [AdditionalCashbackAdjustmentCategoryID] SMALLINT       NOT NULL,
    [PaymentMethodID]                        SMALLINT       NOT NULL,
    [VAT]                                    SMALLMONEY     NULL,
    [VATRate]                                DECIMAL (4, 2) NULL,
    [SourceAddedDate]                        DATE           NULL,
    [CreatedDateTime]                        DATETIME2 (7)  NOT NULL,
    [ItemID]                                 INT            NULL
);

