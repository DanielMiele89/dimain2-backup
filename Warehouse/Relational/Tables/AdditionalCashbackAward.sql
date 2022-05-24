CREATE TABLE [Relational].[AdditionalCashbackAward] (
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
    CONSTRAINT [PK__AdditionCashbackAwardID] PRIMARY KEY CLUSTERED ([AdditionalCashbackAwardID] ASC) WITH (DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IX_ArchiveRef]
    ON [Relational].[AdditionalCashbackAward]([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 80);


GO
ALTER INDEX [IX_ArchiveRef]
    ON [Relational].[AdditionalCashbackAward] DISABLE;


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [Relational].[AdditionalCashbackAward]([AdditionalCashbackAwardTypeID] ASC, [TranDate] ASC)
    INCLUDE([FanID], [CashbackEarned]) WITH (FILLFACTOR = 80);


GO
ALTER INDEX [ix_Stuff]
    ON [Relational].[AdditionalCashbackAward] DISABLE;


GO
CREATE NONCLUSTERED INDEX [ix_MatchID]
    ON [Relational].[AdditionalCashbackAward]([MatchID] ASC)
    INCLUDE([FileID], [RowNum]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [ix_AddedDate]
    ON [Relational].[AdditionalCashbackAward]([PaymentMethodID] ASC, [AddedDate] ASC)
    INCLUDE([FanID], [Amount], [CashbackEarned], [TranDate], [AdditionalCashbackAwardTypeID], [ActivationDays], [MatchID], [DirectDebitOriginatorID], [FileID], [RowNum]) WITH (FILLFACTOR = 75, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_AdditionalCashbackAwardTypeID]
    ON [Relational].[AdditionalCashbackAward]([AdditionalCashbackAwardTypeID] ASC, [TranDate] ASC)
    INCLUDE([FanID], [CashbackEarned], [AdditionalCashbackAwardID]) WITH (FILLFACTOR = 75, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE STATISTICS [st_AddedDate]
    ON [Relational].[AdditionalCashbackAward]([AddedDate]);

