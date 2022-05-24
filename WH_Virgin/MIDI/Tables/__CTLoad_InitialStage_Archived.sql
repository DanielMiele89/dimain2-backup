CREATE TABLE [MIDI].[__CTLoad_InitialStage_Archived] (
    [FileID]                 INT          NOT NULL,
    [RowNum]                 INT          NOT NULL,
    [BankIDString]           VARCHAR (4)  NOT NULL,
    [BankID]                 TINYINT      NULL,
    [MID]                    VARCHAR (50) NOT NULL,
    [Narrative]              VARCHAR (22) NOT NULL,
    [LocationAddress]        VARCHAR (18) NOT NULL,
    [LocationCountry]        VARCHAR (3)  NOT NULL,
    [MCC]                    VARCHAR (4)  NOT NULL,
    [CardholderPresentData]  TINYINT      NOT NULL,
    [TranDate]               DATE         NOT NULL,
    [PaymentCardID]          INT          NULL,
    [CIN]                    VARCHAR (20) NULL,
    [CINID]                  INT          NULL,
    [Amount]                 MONEY        NOT NULL,
    [IsOnline]               BIT          NULL,
    [IsRefund]               BIT          NULL,
    [OriginatorID]           VARCHAR (11) NOT NULL,
    [PostStatus]             CHAR (1)     NOT NULL,
    [MCCID]                  SMALLINT     NULL,
    [PostStatusID]           TINYINT      NULL,
    [LocationID]             INT          NULL,
    [ConsumerCombinationID]  INT          NULL,
    [SecondaryCombinationID] INT          NULL,
    [RequiresSecondaryID]    BIT          CONSTRAINT [DF_MIDI_CTLoad_InitialStage_RequiresSecondaryID] DEFAULT ((0)) NOT NULL,
    [InputModeID]            TINYINT      CONSTRAINT [DF_MIDI_CTLoad_InitialStage_InputModeID] DEFAULT ((0)) NOT NULL,
    [PaymentTypeID]          TINYINT      CONSTRAINT [DF_MIDI_CTLoad_InitialStage_PaymentTypeID] DEFAULT ((1)) NOT NULL,
    [CardInputMode]          CHAR (1)     NULL,
    [BrandMIDID]             INT          NULL,
    CONSTRAINT [PK_MIDI_CTLoad_InitialStage] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [MIDI].[__CTLoad_InitialStage_Archived]([ConsumerCombinationID] ASC, [Narrative] ASC)
    INCLUDE([FileID], [RowNum], [MID], [LocationCountry], [OriginatorID], [MCCID]) WITH (FILLFACTOR = 80);


GO
ALTER INDEX [ix_Stuff]
    ON [MIDI].[__CTLoad_InitialStage_Archived] DISABLE;

