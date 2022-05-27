CREATE TABLE [Staging].[CTLoad_MIDINewCombo_DataMining] (
    [ID]                 INT        IDENTITY (1, 1) NOT NULL,
    [ComboID]            INT        NOT NULL,
    [SuggestedBrandID]   SMALLINT   NOT NULL,
    [ProbabilityOrdinal] TINYINT    NOT NULL,
    [Probability]        FLOAT (53) NULL,
    CONSTRAINT [PK_Staging_CTLoad_MIDINewCombo_DataMining] PRIMARY KEY CLUSTERED ([ID] ASC)
);

