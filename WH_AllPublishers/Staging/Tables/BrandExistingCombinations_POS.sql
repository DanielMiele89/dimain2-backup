CREATE TABLE [Staging].[BrandExistingCombinations_POS] (
    [ID]                    INT           IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID] BIGINT        NULL,
    [DataSource]            VARCHAR (50)  NULL,
    [MID]                   VARCHAR (50)  NULL,
    [Narrative]             VARCHAR (250) NULL,
    [MCCID]                 INT           NULL,
    [BrandID]               INT           NULL,
    [OriginatorID]          VARCHAR (50)  NULL,
    [LocationCountry]       VARCHAR (15)  NULL
);

