CREATE TABLE [Relational].[AdditionalCashbackAdjustmentCategory] (
    [AdditionalCashbackAdjustmentCategoryID] TINYINT      IDENTITY (1, 1) NOT NULL,
    [Category]                               VARCHAR (40) NOT NULL,
    PRIMARY KEY CLUSTERED ([AdditionalCashbackAdjustmentCategoryID] ASC)
);

