CREATE TABLE [Staging].[ConsumerTransactionWorking] (
    [FileID]              INT          NOT NULL,
    [RowNum]              INT          NOT NULL,
    [BrandMIDID]          INT          NULL,
    [BrandCombinationID]  INT          NULL,
    [BankID]              TINYINT      NOT NULL,
    [MID]                 VARCHAR (50) NOT NULL,
    [Narrative]           VARCHAR (50) NOT NULL,
    [LocationAddress]     VARCHAR (50) NOT NULL,
    [LocationID]          INT          NULL,
    [LocationCountry]     VARCHAR (3)  NOT NULL,
    [MCCID]               SMALLINT     NULL,
    [CardholderPresentID] TINYINT      NULL,
    [TranDate]            DATE         NULL,
    [CINID]               INT          NOT NULL,
    [PostStatus]          CHAR (1)     NOT NULL,
    [Amount]              MONEY        NOT NULL,
    [IsRefund]            BIT          NULL,
    [IsOnline]            BIT          NULL,
    [InputModeID]         TINYINT      NULL,
    [PostStatusID]        TINYINT      NULL,
    [OriginatorID]        VARCHAR (11) NOT NULL,
    [SecondaryID]         INT          NULL,
    [RequiresSecondaryID] BIT          CONSTRAINT [DF_Staging_ConsumerTransactionWorking] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_Staging_ConsumerTransactionWorking] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Staging_ConsumerTransactionWorking_Location]
    ON [Staging].[ConsumerTransactionWorking]([BrandCombinationID] ASC, [LocationAddress] ASC);

