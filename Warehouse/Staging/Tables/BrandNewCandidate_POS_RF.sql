CREATE TABLE [Staging].[BrandNewCandidate_POS_RF] (
    [ConsumerCombinationID] BIGINT        NULL,
    [MID]                   VARCHAR (50)  NULL,
    [Narrative]             VARCHAR (250) NULL,
    [MCCID]                 INT           NULL,
    [BrandID]               INT           NULL,
    [OriginatorID]          VARCHAR (50)  NULL,
    [LocationCountry]       VARCHAR (15)  NULL
);


GO
CREATE NONCLUSTERED INDEX [CIX_CCID]
    ON [Staging].[BrandNewCandidate_POS_RF]([ConsumerCombinationID] ASC);

