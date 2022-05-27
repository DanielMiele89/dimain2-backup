CREATE TABLE [APW].[SchemeTrans_Pipe] (
    [ID]                  INT        NOT NULL,
    [Spend]               MONEY      NOT NULL,
    [RetailerCashback]    MONEY      NOT NULL,
    [TranDate]            DATE       NOT NULL,
    [AddedDate]           DATE       NOT NULL,
    [FanID]               INT        NOT NULL,
    [RetailerID]          INT        NOT NULL,
    [PublisherID]         INT        NOT NULL,
    [PublisherCommission] MONEY      NOT NULL,
    [RewardCommission]    SMALLMONEY NOT NULL,
    [IsNegative]          BIT        CONSTRAINT [DF_APW_SchemeTrans_Pipe_IsNegative] DEFAULT ((0)) NOT NULL,
    [Investment]          MONEY      NOT NULL,
    [IsOnline]            BIT        NOT NULL,
    [SpendStretchAmount]  MONEY      NULL,
    [IsSpendStretch]      BIT        NULL,
    [IronOfferID]         INT        NULL,
    [OutletID]            INT        NOT NULL,
    [PanID]               INT        NULL,
    [SubPublisherID]      TINYINT    NOT NULL,
    [IsRetailerReport]    BIT        NOT NULL,
    CONSTRAINT [PK_APW_SchemeTrans_Pipe] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [APW].[SchemeTrans_Pipe]([IsRetailerReport] ASC, [IronOfferID] ASC)
    INCLUDE([Spend], [TranDate], [FanID], [RetailerID]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

