CREATE TABLE [Staging].[AllocatedTranID_OLD] (
    [TranID]                         INT NULL,
    [MatchID]                        INT NULL,
    [SchemeTransID]                  INT NULL,
    [AdditionalCashbackAwardID]      INT NULL,
    [isAdditionalCashbackAdjustment] BIT DEFAULT ((0)) NOT NULL
);


GO
CREATE CLUSTERED INDEX [cx_SchemeTransID]
    ON [Staging].[AllocatedTranID_OLD]([SchemeTransID] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [ix_matchid]
    ON [Staging].[AllocatedTranID_OLD]([MatchID] ASC) WHERE ([MatchID] IS NOT NULL) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [ix_tranid]
    ON [Staging].[AllocatedTranID_OLD]([TranID] ASC) WHERE ([TranID] IS NOT NULL) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

