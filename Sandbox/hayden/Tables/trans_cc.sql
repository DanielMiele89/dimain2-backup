CREATE TABLE [hayden].[trans_cc] (
    [FileID]                INT     NOT NULL,
    [RowNum]                INT     NOT NULL,
    [ConsumerCombinationID] INT     NOT NULL,
    [CardholderPresentData] TINYINT NOT NULL,
    [TranDate]              DATE    NOT NULL,
    [CINID]                 INT     NOT NULL,
    [Amount]                MONEY   NOT NULL,
    [IsOnline]              BIT     NOT NULL,
    [LocationID]            INT     NOT NULL,
    [FanID]                 INT     NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [hayden].[trans_cc]([FileID] ASC, [RowNum] ASC);


GO
CREATE NONCLUSTERED INDEX [NIX]
    ON [hayden].[trans_cc]([TranDate] ASC);

