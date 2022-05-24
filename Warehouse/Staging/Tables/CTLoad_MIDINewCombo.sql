CREATE TABLE [Staging].[CTLoad_MIDINewCombo] (
    [ID]               INT          IDENTITY (1, 1) NOT NULL,
    [MID]              VARCHAR (50) NOT NULL,
    [Narrative]        VARCHAR (50) NOT NULL,
    [LocationCountry]  VARCHAR (3)  NOT NULL,
    [MCCID]            SMALLINT     NOT NULL,
    [OriginatorID]     VARCHAR (11) NOT NULL,
    [IsHighVariance]   BIT          CONSTRAINT [DF_Staging_CTLoad_MIDINewCombo_IsHighVariance] DEFAULT ((0)) NOT NULL,
    [SuggestedBrandID] SMALLINT     NULL,
    [MatchType]        TINYINT      NULL,
    [AcquirerID]       TINYINT      NOT NULL,
    [MatchCount]       INT          CONSTRAINT [DF_Staging_CTLoad_MIDINewCombo] DEFAULT ((1)) NULL,
    [BrandProbability] FLOAT (53)   NULL,
    [IsUKSpend]        BIT          NULL,
    [IsCreditOrigin]   BIT          CONSTRAINT [DF_staging_ctload_MIDINewCombo_IsCreditOrigin] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Staging_CTLoad_MIDINewCombo] PRIMARY KEY CLUSTERED ([ID] ASC)
);

