CREATE TABLE [Staging].[AdditionalCashbackAward_OLD] (
    [AdditionalCashbackAwardID]     INT        NOT NULL,
    [MatchID]                       INT        NULL,
    [FileID]                        INT        NOT NULL,
    [RowNum]                        INT        NOT NULL,
    [FanID]                         INT        NOT NULL,
    [TranDate]                      DATE       NOT NULL,
    [AddedDate]                     DATE       NOT NULL,
    [Amount]                        SMALLMONEY NOT NULL,
    [CashbackEarned]                SMALLMONEY NOT NULL,
    [ActivationDays]                INT        NOT NULL,
    [AdditionalCashbackAwardTypeID] TINYINT    NOT NULL,
    [PaymentMethodID]               TINYINT    NULL,
    [DirectDebitOriginatorID]       INT        NULL,
    [SchemeTransID]                 INT        NOT NULL
);


GO
CREATE CLUSTERED INDEX [UCIX]
    ON [Staging].[AdditionalCashbackAward_OLD]([AdditionalCashbackAwardID] ASC);


GO
CREATE NONCLUSTERED INDEX [NIX]
    ON [Staging].[AdditionalCashbackAward_OLD]([AdditionalCashbackAwardTypeID] ASC)
    INCLUDE([FileID], [RowNum], [AdditionalCashbackAwardID], [SchemeTransID]);

