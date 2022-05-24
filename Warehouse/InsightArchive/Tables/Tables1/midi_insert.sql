CREATE TABLE [InsightArchive].[midi_insert] (
    [ID]               INT          NOT NULL,
    [MID]              VARCHAR (50) NOT NULL,
    [Narrative]        VARCHAR (50) NOT NULL,
    [LocationCountry]  VARCHAR (3)  NOT NULL,
    [MCCID]            SMALLINT     NOT NULL,
    [OriginatorID]     VARCHAR (11) NOT NULL,
    [IsHighVariance]   BIT          NOT NULL,
    [SuggestedBrandID] SMALLINT     NULL,
    [MatchType]        TINYINT      NULL,
    [AcquirerID]       TINYINT      NOT NULL,
    [MatchCount]       INT          NULL,
    [BrandProbability] FLOAT (53)   NULL,
    [IsUKSpend]        BIT          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

