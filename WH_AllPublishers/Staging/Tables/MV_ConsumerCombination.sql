CREATE TABLE [Staging].[MV_ConsumerCombination] (
    [ConsumerCombinationID] INT          NOT NULL,
    [MID]                   VARCHAR (50) NOT NULL,
    [Narrative]             VARCHAR (50) NOT NULL,
    [Narrative_Cleaned]     VARCHAR (50) NULL,
    [LocationCountry]       VARCHAR (3)  NOT NULL,
    [MCCID]                 SMALLINT     NOT NULL,
    [OriginatorID]          VARCHAR (11) NOT NULL,
    [BrandID]               SMALLINT     NOT NULL,
    [PartnerID]             INT          NOT NULL,
    [MIDTypeID]             TINYINT      NULL,
    [MIDStatusID]           TINYINT      NULL
);


GO
CREATE CLUSTERED INDEX [CIX_CCID]
    ON [Staging].[MV_ConsumerCombination]([ConsumerCombinationID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_All]
    ON [Staging].[MV_ConsumerCombination]([MID] ASC, [LocationCountry] ASC, [MCCID] ASC, [OriginatorID] ASC) WITH (FILLFACTOR = 90);

