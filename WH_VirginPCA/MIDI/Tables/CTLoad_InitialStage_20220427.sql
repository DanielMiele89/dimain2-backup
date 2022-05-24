CREATE TABLE [MIDI].[CTLoad_InitialStage_20220427] (
    [FileID]                 INT              NULL,
    [RowNum]                 VARCHAR (100)    NULL,
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
CREATE NONCLUSTERED INDEX [IX_CardID]
    ON [MIDI].[CTLoad_InitialStage_20220427]([CardID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CardIDBankCIN]
    ON [MIDI].[CTLoad_InitialStage_20220427]([CardID] ASC, [BankID] ASC, [CIN] ASC, [CINID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CardInputMode]
    ON [MIDI].[CTLoad_InitialStage_20220427]([CardInputMode] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CCID]
    ON [MIDI].[CTLoad_InitialStage_20220427]([ConsumerCombinationID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CIN]
    ON [MIDI].[CTLoad_InitialStage_20220427]([CIN] ASC, [CINID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MCC]
    ON [MIDI].[CTLoad_InitialStage_20220427]([MCC] ASC, [MCCID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MerchantCountry]
    ON [MIDI].[CTLoad_InitialStage_20220427]([MerchantCountry] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MID]
    ON [MIDI].[CTLoad_InitialStage_20220427]([MID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MIDCountryMCCIDMerchantName]
    ON [MIDI].[CTLoad_InitialStage_20220427]([MID] ASC, [MerchantCountry] ASC, [MCCID] ASC, [MerchantName] ASC);

