﻿CREATE TABLE [Staging].[ConsumerTransactionCatchup] (
    [FileID]                INT          NOT NULL,
    [RowNum]                INT          NOT NULL,
    [BrandMIDID]            INT          NULL,
    [BrandCombinationID]    INT          NULL,
    [BankID]                TINYINT      NOT NULL,
    [MID]                   VARCHAR (50) NOT NULL,
    [Narrative]             VARCHAR (50) NOT NULL,
    [LocationAddress]       VARCHAR (50) NOT NULL,
    [LocationID]            INT          NULL,
    [LocationCountry]       VARCHAR (3)  NOT NULL,
    [MCC]                   VARCHAR (4)  NOT NULL,
    [MCCID]                 SMALLINT     NULL,
    [CardholderPresentData] VARCHAR (1)  NOT NULL,
    [CardholderPresentID]   TINYINT      NULL,
    [TranDate]              DATE         NULL,
    [CINID]                 INT          NOT NULL,
    [PostStatus]            CHAR (1)     NOT NULL,
    [Amount]                MONEY        NOT NULL,
    [IsRefund]              BIT          NULL,
    [IsOnline]              BIT          NULL,
    [PostStatusID]          TINYINT      NULL,
    [OriginatorID]          VARCHAR (11) NOT NULL,
    CONSTRAINT [PK_Staging_ConsumerTransactionCatchup] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Staging_ConsumerTransactionCatchup]
    ON [Staging].[ConsumerTransactionCatchup]([BrandMIDID] ASC, [MCCID] ASC, [OriginatorID] ASC);

