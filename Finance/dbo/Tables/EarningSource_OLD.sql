CREATE TABLE [dbo].[EarningSource_OLD] (
    [EarningSourceID]                        INT           IDENTITY (1, 1) NOT NULL,
    [SourceName]                             VARCHAR (50)  NOT NULL,
    [PartnerID]                              INT           NOT NULL,
    [isBankFunded]                           BIT           NULL,
    [AdditionalCashbackAwardTypeID]          SMALLINT      NOT NULL,
    [AdditionalCashbackAdjustmentTypeID]     SMALLINT      NOT NULL,
    [AdditionalCashbackAdjustmentCategoryID] SMALLINT      NOT NULL,
    [DDCategory]                             VARCHAR (50)  NOT NULL,
    [DisplayCategory]                        VARCHAR (50)  NOT NULL,
    [MultiplePaymentMethods]                 BIT           NULL,
    [Phase]                                  VARCHAR (50)  NOT NULL,
    [CreatedDateTime]                        DATETIME2 (7) NOT NULL,
    [UpdatedDateTime]                        DATETIME2 (7) NOT NULL,
    [FundingType]                            VARCHAR (20)  NULL,
    [DisplayName]                            VARCHAR (100) NULL,
    CONSTRAINT [PK_dbo_EarningSource_OLD] PRIMARY KEY CLUSTERED ([EarningSourceID] ASC),
    CONSTRAINT [FK_EarningSource_AdditionalCashbackAdjustmentCategoryID_OLD] FOREIGN KEY ([AdditionalCashbackAdjustmentCategoryID]) REFERENCES [dbo].[AdditionalCashbackAdjustmentCategory_OLD] ([AdditionalCashbackAdjustmentCategoryID]),
    CONSTRAINT [FK_EarningSource_AdditionalCashbackAdjustmentTypeID_OLD] FOREIGN KEY ([AdditionalCashbackAdjustmentTypeID]) REFERENCES [dbo].[AdditionalCashbackAdjustmentType_OLD] ([AdditionalCashbackAdjustmentTypeID]),
    CONSTRAINT [FK_EarningSource_AdditionalCashbackAwardTypeID_OLD] FOREIGN KEY ([AdditionalCashbackAwardTypeID]) REFERENCES [dbo].[AdditionalCashbackAwardType_OLD] ([AdditionalCashbackAwardTypeID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNIX_Key]
    ON [dbo].[EarningSource_OLD]([PartnerID] ASC, [AdditionalCashbackAwardTypeID] ASC, [AdditionalCashbackAdjustmentTypeID] ASC, [AdditionalCashbackAdjustmentCategoryID] ASC, [DDCategory] ASC);

