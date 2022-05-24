CREATE TABLE [MIDI].[CTLoad_InitialStage] (
    [FileID]                 INT              NULL,
    [RowNum]                 BIGINT           NULL,
    [FileName]               NVARCHAR (100)   NULL,
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
    [TranDate]               DATE             NULL,
    [TranTime]               TIME (7)         NULL,
    [Amount]                 MONEY            NULL,
    [CurrencyCode]           VARCHAR (50)     NULL,
    [CardInputMode]          VARCHAR (50)     NULL,
    [InputModeID]            INT              NULL,
    [PaymentTypeID]          INT              NULL,
    [CashbackAmount]         MONEY            NULL,
    [IsOnline]               BIT              NULL,
    [IsRefund]               BIT              NULL,
    [ConsumerCombinationID]  INT              NULL,
    [RequiresSecondaryID]    BIT              NULL,
    [SecondaryCombinationID] INT              NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_MCC]
    ON [MIDI].[CTLoad_InitialStage]([MCC] ASC, [MCCID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CardID]
    ON [MIDI].[CTLoad_InitialStage]([CardID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CardIDBankCIN]
    ON [MIDI].[CTLoad_InitialStage]([CardID] ASC, [BankID] ASC, [CIN] ASC, [CINID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CIN]
    ON [MIDI].[CTLoad_InitialStage]([CIN] ASC, [CINID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CardInputMode]
    ON [MIDI].[CTLoad_InitialStage]([CardInputMode] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MID]
    ON [MIDI].[CTLoad_InitialStage]([MID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MIDCountryMCCIDMerchantName]
    ON [MIDI].[CTLoad_InitialStage]([MID] ASC, [MerchantCountry] ASC, [MCCID] ASC, [MerchantName] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CCID]
    ON [MIDI].[CTLoad_InitialStage]([ConsumerCombinationID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MerchantCountry]
    ON [MIDI].[CTLoad_InitialStage]([MerchantCountry] ASC);

