CREATE TABLE [MIDI].[PaymentGatewaySecondaryDetail] (
    [PaymentGatewayID]      INT          IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID] INT          NOT NULL,
    [MID]                   VARCHAR (50) NOT NULL,
    [Narrative]             VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_MIDI_PaymentGatewaySecondaryDetail] PRIMARY KEY CLUSTERED ([PaymentGatewayID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [MIDI].[PaymentGatewaySecondaryDetail]([ConsumerCombinationID] ASC, [MID] ASC, [Narrative] ASC)
    INCLUDE([PaymentGatewayID]);

