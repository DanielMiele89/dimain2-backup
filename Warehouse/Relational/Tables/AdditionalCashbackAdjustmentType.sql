CREATE TABLE [Relational].[AdditionalCashbackAdjustmentType] (
    [AdditionalCashbackAdjustmentTypeID]     INT           IDENTITY (1, 1) NOT NULL,
    [TypeID]                                 TINYINT       NOT NULL,
    [ItemID]                                 INT           NOT NULL,
    [Description]                            VARCHAR (100) NOT NULL,
    [AdditionalCashbackAdjustmentCategoryID] TINYINT       NULL,
    CONSTRAINT [PK__Addition__E4A9F0610A38C44F] PRIMARY KEY CLUSTERED ([AdditionalCashbackAdjustmentTypeID] ASC)
);

