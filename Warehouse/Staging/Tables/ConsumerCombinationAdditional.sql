CREATE TABLE [Staging].[ConsumerCombinationAdditional] (
    [ConsumerCombinationID] INT          IDENTITY (1, 1) NOT NULL,
    [BrandMIDID]            INT          NOT NULL,
    [BrandID]               SMALLINT     NOT NULL,
    [MID]                   VARCHAR (50) NOT NULL,
    [Narrative]             VARCHAR (50) NOT NULL,
    [LocationCountry]       VARCHAR (3)  NOT NULL,
    [MCCID]                 SMALLINT     NOT NULL,
    [OriginatorID]          VARCHAR (11) NOT NULL,
    [IsHighVariance]        BIT          NOT NULL,
    [Frequency]             INT          NOT NULL,
    CONSTRAINT [PK_Staging_ConsumerCombinationAdditional] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

