CREATE TABLE [Relational].[AdditionalCashbackAdjustment_incTranID] (
    [FanID]                              INT        NOT NULL,
    [TranID]                             INT        NOT NULL,
    [AddedDate]                          DATETIME   NOT NULL,
    [CashbackEarned]                     SMALLMONEY NULL,
    [ActivationDays]                     INT        NOT NULL,
    [AdditionalCashbackAdjustmentTypeID] INT        NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [Relational].[AdditionalCashbackAdjustment_incTranID]([TranID] ASC);

