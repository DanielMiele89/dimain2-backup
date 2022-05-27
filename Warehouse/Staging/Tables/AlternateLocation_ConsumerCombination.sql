CREATE TABLE [Staging].[AlternateLocation_ConsumerCombination] (
    [ConsumerCombinationID] INT          NOT NULL,
    [MIDNumeric]            VARCHAR (50) NOT NULL,
    [Narrative]             VARCHAR (50) NOT NULL,
    [BrandID]               SMALLINT     NOT NULL,
    CONSTRAINT [PK_Staging_AlternateLocation_ConsumerCombination] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

