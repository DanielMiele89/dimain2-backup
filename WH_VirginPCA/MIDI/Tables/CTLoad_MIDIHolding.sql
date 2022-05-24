﻿CREATE TABLE [MIDI].[CTLoad_MIDIHolding] (
    [TransactionID]          VARCHAR (100)    NOT NULL,
    [FileID]                 INT              NOT NULL,
    [RowNum]                 VARCHAR (100)    NOT NULL,
    [FileName]               NVARCHAR (500)   NULL,
    [LoadDate]               DATETIME2 (7)    NULL,
    [CardID]                 UNIQUEIDENTIFIER NULL,
    [BankID]                 INT              NULL,
    [CIN]                    VARCHAR (50)     NULL,
    [CINID]                  BIGINT           NULL,
    [MID]                    VARCHAR (100)    NULL,
    [MerchantCountry]        VARCHAR (100)    NULL,
    [LocationID]             BIGINT           NULL,
    [LocationAddress]        VARCHAR (100)    NULL,
    [MerchantName]           NVARCHAR (200)   NULL,
    [CardholderPresentData]  VARCHAR (50)     NULL,
    [MCC]                    VARCHAR (50)     NULL,
    [MCCID]                  INT              NULL,
    [MerchantAcquirerBin]    INT              NULL,
    [TranDate]               DATETIME2 (0)    NOT NULL,
    [Amount]                 MONEY            NULL,
    [CurrencyCode]           VARCHAR (50)     NULL,
    [CardInputMode]          VARCHAR (50)     NULL,
    [InputModeID]            INT              NULL,
    [PaymentTypeID]          INT              NULL,
    [CashbackAmount]         MONEY            NULL,
    [IsOnline]               BIT              NULL,
    [IsRefund]               BIT              NULL,
    [ConsumerCombinationID]  INT              NULL,
    [RequiresSecondaryID]    BIT              CONSTRAINT [DF_Staging_CTLoad_MIDIHolding] DEFAULT ((0)) NULL,
    [SecondaryCombinationID] INT              NULL,
    CONSTRAINT [PK_Staging_CTLoad_MIDIHolding] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [CIX_TranNarrative]
    ON [MIDI].[CTLoad_MIDIHolding]([FileID] ASC, [TransactionID] ASC, [MerchantName] ASC) WITH (FILLFACTOR = 90);

