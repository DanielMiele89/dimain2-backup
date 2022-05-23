CREATE TABLE [dbo].[AdditionalCashbackAdjustmentCategory_OLD] (
    [AdditionalCashbackAdjustmentCategoryID] SMALLINT      NOT NULL,
    [Category]                               VARCHAR (40)  NOT NULL,
    [CreatedDateTime]                        DATETIME2 (7) NOT NULL,
    [UpdatedDateTime]                        DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_AdditionalCashbackAdjustmentCategory_OLD] PRIMARY KEY CLUSTERED ([AdditionalCashbackAdjustmentCategoryID] ASC)
);

