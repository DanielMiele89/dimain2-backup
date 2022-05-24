CREATE TABLE [Derived].[__AdditionalCashbackAward_Archived] (
    [AdditionalCashbackAwardID]     INT        IDENTITY (1, 1) NOT NULL,
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
    CONSTRAINT [PK__AdditionCashbackAwardID] PRIMARY KEY CLUSTERED ([AdditionalCashbackAwardID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ArchiveRef]
    ON [Derived].[__AdditionalCashbackAward_Archived]([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_MatchID]
    ON [Derived].[__AdditionalCashbackAward_Archived]([MatchID] ASC)
    INCLUDE([CashbackEarned], [FanID], [AddedDate]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [Derived].[__AdditionalCashbackAward_Archived]([AdditionalCashbackAwardTypeID] ASC, [TranDate] ASC)
    INCLUDE([FanID], [CashbackEarned]) WITH (FILLFACTOR = 80);

