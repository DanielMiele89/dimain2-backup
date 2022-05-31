CREATE TABLE [PatrickM].[CashbackSource] (
    [ID]                                     INT          NOT NULL,
    [SourceName]                             VARCHAR (50) NOT NULL,
    [PartnerID]                              INT          NOT NULL,
    [RBSFunded]                              TINYINT      NOT NULL,
    [AdditionalCashbackAwardTypeID]          TINYINT      NOT NULL,
    [AdditionalCashbackAdjustmentTypeID]     TINYINT      NOT NULL,
    [AdditionalCashbackAdjustmentCategoryID] TINYINT      NOT NULL,
    [DDCategory]                             VARCHAR (50) NOT NULL,
    [MultiplePaymentMethods]                 BIT          NOT NULL,
    [Phase]                                  VARCHAR (50) NOT NULL,
    [Included]                               TINYINT      NOT NULL
);

