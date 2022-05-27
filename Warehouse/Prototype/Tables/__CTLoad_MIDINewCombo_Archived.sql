CREATE TABLE [Prototype].[__CTLoad_MIDINewCombo_Archived] (
    [ID]                INT           IDENTITY (1, 1) NOT NULL,
    [MID]               VARCHAR (50)  NOT NULL,
    [Narrative]         VARCHAR (50)  NOT NULL,
    [Narrative_Cleaned] VARCHAR (250) NULL,
    [LocationCountry]   VARCHAR (3)   NOT NULL,
    [MCCID]             SMALLINT      NOT NULL,
    [OriginatorID]      VARCHAR (11)  NOT NULL,
    [IsHighVariance]    BIT           NOT NULL,
    [SuggestedBrandID]  SMALLINT      NULL,
    [MatchType]         TINYINT       NULL,
    [AcquirerID]        TINYINT       NOT NULL,
    [MatchCount]        INT           NULL,
    [BrandProbability]  FLOAT (53)    NULL,
    [IsUKSpend]         BIT           NULL,
    [IsCreditOrigin]    BIT           NOT NULL,
    [IsPrefixRemoved]   BIT           NULL
);

