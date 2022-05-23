CREATE TABLE [dbo].[EarningSource2_OLD] (
    [EarningSourceID]                        INT           NOT NULL,
    [SourceName]                             VARCHAR (50)  NOT NULL,
    [PartnerID]                              INT           NOT NULL,
    [isBankFunded]                           BIT           NULL,
    [AdditionalCashbackAwardTypeID]          SMALLINT      NOT NULL,
    [AdditionalCashbackAdjustmentTypeID]     SMALLINT      NOT NULL,
    [AdditionalCashbackAdjustmentCategoryID] SMALLINT      NOT NULL,
    [DDCategory]                             VARCHAR (50)  NOT NULL,
    [PortalCategory]                         VARCHAR (50)  NOT NULL,
    [MultiplePaymentMethods]                 BIT           NULL,
    [Phase]                                  VARCHAR (50)  NOT NULL,
    [CreatedDateTime]                        DATETIME2 (7) NOT NULL,
    [UpdatedDateTime]                        DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_dbo_EarningSource2_OLD] PRIMARY KEY CLUSTERED ([EarningSourceID] ASC),
    CONSTRAINT [FK_EarningSource_AdditionalCashbackAdjustmentCategoryID2_OLD] FOREIGN KEY ([AdditionalCashbackAdjustmentCategoryID]) REFERENCES [dbo].[AdditionalCashbackAdjustmentCategory_OLD] ([AdditionalCashbackAdjustmentCategoryID]),
    CONSTRAINT [FK_EarningSource_AdditionalCashbackAdjustmentTypeID2_OLD] FOREIGN KEY ([AdditionalCashbackAdjustmentTypeID]) REFERENCES [dbo].[AdditionalCashbackAdjustmentType_OLD] ([AdditionalCashbackAdjustmentTypeID]),
    CONSTRAINT [FK_EarningSource_AdditionalCashbackAwardTypeID2_OLD] FOREIGN KEY ([AdditionalCashbackAwardTypeID]) REFERENCES [dbo].[AdditionalCashbackAwardType_OLD] ([AdditionalCashbackAwardTypeID])
);

