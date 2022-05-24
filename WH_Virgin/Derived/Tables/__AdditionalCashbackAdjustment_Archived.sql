CREATE TABLE [Derived].[__AdditionalCashbackAdjustment_Archived] (
    [AdditionalCashbackAdjustmentID]     INT        IDENTITY (1, 1) NOT NULL,
    [FanID]                              INT        NOT NULL,
    [AddedDate]                          DATE       NOT NULL,
    [CashbackEarned]                     SMALLMONEY NOT NULL,
    [ActivationDays]                     INT        NOT NULL,
    [AdditionalCashbackAdjustmentTypeID] TINYINT    NOT NULL,
    CONSTRAINT [PK__AdditionalCashbackAdjustmentID] PRIMARY KEY CLUSTERED ([AdditionalCashbackAdjustmentID] ASC)
);

