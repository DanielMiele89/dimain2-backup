CREATE TABLE [MIDI].[__CreditCardLoad_InitialStage_Archived] (
    [FileID]                 INT          NOT NULL,
    [RowNum]                 INT          NOT NULL,
    [OriginatorReference]    VARCHAR (6)  NOT NULL,
    [LocationCountry]        VARCHAR (3)  NOT NULL,
    [MID]                    VARCHAR (50) NOT NULL,
    [Narrative]              VARCHAR (50) NOT NULL,
    [MCC]                    VARCHAR (4)  NOT NULL,
    [PostCode]               VARCHAR (9)  NOT NULL,
    [CIN]                    VARCHAR (15) NOT NULL,
    [CardholderPresentMC]    CHAR (1)     NOT NULL,
    [Amount]                 SMALLMONEY   NOT NULL,
    [TranDateString]         VARCHAR (10) NOT NULL,
    [TranDate]               DATE         NULL,
    [ConsumerCombinationID]  INT          NULL,
    [SecondaryCombinationID] INT          NULL,
    [RequiresSecondaryID]    BIT          CONSTRAINT [DF_Midi_CreditCardLoad_InitialStage_RequiresSecondaryID] DEFAULT ((0)) NOT NULL,
    [MCCID]                  SMALLINT     NULL,
    [LocationID]             INT          NULL,
    [CINID]                  INT          NULL,
    [PaymentTypeID]          TINYINT      CONSTRAINT [DF_Midi_CreditCardLoad_InitialStage_PaymentTypeID] DEFAULT ((1)) NOT NULL,
    [FanID]                  INT          NULL,
    CONSTRAINT [PK_Midi_CreditCardLoad_InitialStage] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_stuff2]
    ON [MIDI].[__CreditCardLoad_InitialStage_Archived]([ConsumerCombinationID] ASC, [Narrative] ASC);


GO
CREATE NONCLUSTERED INDEX [ix_stuff3]
    ON [MIDI].[__CreditCardLoad_InitialStage_Archived]([Narrative] ASC, [ConsumerCombinationID] ASC)
    INCLUDE([LocationCountry], [MCCID], [OriginatorReference], [MID], [RequiresSecondaryID]) WITH (FILLFACTOR = 80);

