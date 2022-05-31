CREATE TABLE [dbo].[NobleTransactionHistory_MIDI] (
    [FileID]                INT           NULL,
    [RowNum]                INT           NULL,
    [BankID]                VARCHAR (4)   NULL,
    [MerchantID]            NVARCHAR (50) NULL,
    [LocationName]          NVARCHAR (22) NULL,
    [LocationAddress]       NVARCHAR (18) NULL,
    [LocationCountry]       NVARCHAR (3)  NULL,
    [MCC]                   VARCHAR (4)   NULL,
    [CardholderPresentData] CHAR (1)      NULL,
    [TranDate]              VARCHAR (10)  NULL,
    [PaymentCardID]         INT           NULL,
    [Amount]                MONEY         NULL,
    [OriginatorID]          VARCHAR (11)  NULL,
    [PostStatus]            CHAR (1)      NULL,
    [CardInputMode]         CHAR (1)      NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ixc_NobleTransactionHistoryMIDI_FileIDRowNum]
    ON [dbo].[NobleTransactionHistory_MIDI]([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE);


GO
GRANT INSERT
    ON OBJECT::[dbo].[NobleTransactionHistory_MIDI] TO [crtimport]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[NobleTransactionHistory_MIDI] TO [crtimport]
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[NobleTransactionHistory_MIDI] TO [crtimport]
    AS [dbo];

