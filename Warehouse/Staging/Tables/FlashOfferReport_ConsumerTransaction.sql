CREATE TABLE [Staging].[FlashOfferReport_ConsumerTransaction] (
    [PartnerID]              INT     NOT NULL,
    [FileID]                 INT     NOT NULL,
    [RowNum]                 INT     NOT NULL,
    [ConsumerCombinationID]  INT     NOT NULL,
    [SecondaryCombinationID] INT     NULL,
    [BankID]                 TINYINT NOT NULL,
    [LocationID]             INT     NOT NULL,
    [CardholderPresentData]  TINYINT NOT NULL,
    [TranDate]               DATE    NOT NULL,
    [CINID]                  INT     NOT NULL,
    [Amount]                 MONEY   NOT NULL,
    [IsRefund]               BIT     NOT NULL,
    [IsOnline]               BIT     NOT NULL,
    [InputModeID]            TINYINT NOT NULL,
    [PostStatusID]           TINYINT NOT NULL,
    [PaymentTypeID]          TINYINT CONSTRAINT [DF_Relational_ConsumerTransaction_Partitioned_PaymentTypeID] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_FlashOfferReport_ConsumerTransaction] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC, [TranDate] ASC) WITH (FILLFACTOR = 75)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [Staging].[FlashOfferReport_ConsumerTransaction]([PartnerID] ASC, [CINID] ASC, [TranDate] ASC)
    INCLUDE([FileID], [RowNum], [Amount]) WITH (DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_FlashOfferReport_ConsumerTransaction_MainCoverV2]
    ON [Staging].[FlashOfferReport_ConsumerTransaction]([PartnerID] ASC, [TranDate] ASC)
    INCLUDE([Amount], [CINID]);

