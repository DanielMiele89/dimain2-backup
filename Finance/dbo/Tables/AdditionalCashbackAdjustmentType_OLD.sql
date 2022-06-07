CREATE TABLE [dbo].[AdditionalCashbackAdjustmentType_OLD] (
    [AdditionalCashbackAdjustmentTypeID]     SMALLINT      NOT NULL,
    [TransactionTypeID]                      SMALLINT      NOT NULL,
    [ItemID]                                 INT           NULL,
    [TypeDescription]                        VARCHAR (200) NULL,
    [AdditionalCashbackAdjustmentCategoryID] SMALLINT      NULL,
    [CreatedDateTime]                        DATETIME2 (7) NOT NULL,
    [UpdatedDateTime]                        DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_AdditionalCashbackAdjustmentType_OLD] PRIMARY KEY CLUSTERED ([AdditionalCashbackAdjustmentTypeID] ASC),
    CONSTRAINT [FK_AdditionalCashbackAdjustmentType_AdditionalCashbackAdjustmentCategoryID_OLD] FOREIGN KEY ([AdditionalCashbackAdjustmentCategoryID]) REFERENCES [dbo].[AdditionalCashbackAdjustmentCategory_OLD] ([AdditionalCashbackAdjustmentCategoryID]),
    CONSTRAINT [FK_AdditionalCashbackAdjustmentType_TransactionTypeID_OLD] FOREIGN KEY ([TransactionTypeID]) REFERENCES [dbo].[TransactionType_OLD] ([TransactionTypeID])
);

