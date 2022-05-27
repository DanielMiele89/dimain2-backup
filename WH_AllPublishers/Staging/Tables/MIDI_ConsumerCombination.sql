CREATE TABLE [Staging].[MIDI_ConsumerCombination] (
    [BrandID]           SMALLINT      NOT NULL,
    [MID]               VARCHAR (50)  NOT NULL,
    [Narrative]         VARCHAR (150) NOT NULL,
    [Narrative_Cleaned] VARCHAR (150) NOT NULL,
    [LocationCountry]   VARCHAR (3)   NOT NULL,
    [MCCID]             SMALLINT      NOT NULL,
    [OriginatorID]      VARCHAR (11)  NULL,
    [IsHighVariance]    BIT           NOT NULL,
    [Transactions]      INT           NULL,
    [Amount]            MONEY         NULL
);


GO
CREATE CLUSTERED INDEX [CIX_MID]
    ON [Staging].[MIDI_ConsumerCombination]([MID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff3]
    ON [Staging].[MIDI_ConsumerCombination]([LocationCountry] ASC, [MCCID] ASC, [OriginatorID] ASC, [MID] ASC, [Narrative] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff4]
    ON [Staging].[MIDI_ConsumerCombination]([MID] ASC, [LocationCountry] ASC, [MCCID] ASC, [OriginatorID] ASC)
    INCLUDE([Narrative]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff5]
    ON [Staging].[MIDI_ConsumerCombination]([BrandID] ASC)
    INCLUDE([MID], [MCCID], [OriginatorID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff6]
    ON [Staging].[MIDI_ConsumerCombination]([MID] ASC, [MCCID] ASC, [OriginatorID] ASC)
    INCLUDE([BrandID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_MCCIDLocCounBrandID]
    ON [Staging].[MIDI_ConsumerCombination]([MCCID] ASC, [LocationCountry] ASC, [BrandID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE COLUMNSTORE INDEX [CSI_All]
    ON [Staging].[MIDI_ConsumerCombination]([BrandID], [MID], [Narrative], [LocationCountry], [MCCID], [OriginatorID]);

