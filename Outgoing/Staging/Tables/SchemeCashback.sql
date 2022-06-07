CREATE TABLE [Staging].[SchemeCashback] (
    [ID]                                     INT           IDENTITY (1, 1) NOT NULL,
    [SchemeTransID]                          INT           NULL,
    [FanID]                                  INT           NOT NULL,
    [Spend]                                  MONEY         NOT NULL,
    [Cashback]                               MONEY         NOT NULL,
    [AddedDate]                              DATE          NOT NULL,
    [TranDate]                               DATE          NOT NULL,
    [PartnerID]                              INT           NOT NULL,
    [PartnerName]                            VARCHAR (100) NOT NULL,
    [AdditionalCashbackAwardTypeID]          TINYINT       NOT NULL,
    [AdditionalCashbackAdjustmentTypeID]     TINYINT       NOT NULL,
    [AdditionalCashbackAdjustmentCategoryID] TINYINT       NOT NULL,
    [DDCategory]                             VARCHAR (50)  NOT NULL,
    [OfferAboveBase]                         BIT           NULL,
    [PaymentMethodID]                        SMALLINT      NOT NULL,
    [PaymentMethod]                          VARCHAR (50)  NOT NULL,
    [OfferName]                              VARCHAR (200) NULL,
    [ActivationDays]                         TINYINT       NOT NULL,
    [PartnerMatchID]                         INT           NOT NULL
);

