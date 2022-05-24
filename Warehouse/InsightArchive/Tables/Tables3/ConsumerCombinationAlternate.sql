CREATE TABLE [InsightArchive].[ConsumerCombinationAlternate] (
    [ConsumerCombinationID] INT          NOT NULL,
    [BrandID]               SMALLINT     NULL,
    [LocationCountry]       VARCHAR (3)  NULL,
    [MCCID]                 SMALLINT     NULL,
    [IsUKSpend]             BIT          NULL,
    [PostCode]              VARCHAR (50) NULL,
    [LocationID]            INT          NULL,
    [AlternatePostCode]     VARCHAR (50) NULL,
    [AlternateLocationID]   INT          NULL,
    [MID]                   VARCHAR (50) NULL,
    [Narrative]             VARCHAR (50) NULL,
    [CleanedID]             INT          NULL,
    PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);

