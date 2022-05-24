CREATE TABLE [Prototype].[Profiled_ConsumerCombinationIDs] (
    [ConsumerCombinationID] INT     NOT NULL,
    [Channel]               TINYINT NOT NULL,
    [OnlineSales]           INT     NULL,
    [OfflineSales]          INT     NULL,
    [Within10Minutes]       INT     NULL,
    [Within20Minutes]       INT     NULL,
    [Within30Minutes]       INT     NULL,
    [Within40Minutes]       INT     NULL,
    [Within50Minutes]       INT     NULL,
    [Within60Minutes]       INT     NULL,
    [MoreThan60Minutes]     INT     NULL,
    [NegativeTrans]         INT     NULL,
    [PositiveTrans]         INT     NULL,
    [NullTrans]             INT     NULL
);


GO
CREATE CLUSTERED INDEX [cix_ConsumerCombinationID]
    ON [Prototype].[Profiled_ConsumerCombinationIDs]([ConsumerCombinationID] ASC);

