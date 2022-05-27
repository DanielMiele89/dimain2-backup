CREATE TABLE [Staging].[BrandNewCandidate_POS_WA] (
    [ConsumerCombinationID] BIGINT        NULL,
    [MID]                   VARCHAR (50)  NULL,
    [Narrative]             VARCHAR (250) NULL,
    [MCCID]                 INT           NULL,
    [BrandID]               INT           NULL,
    [LocationCountry]       VARCHAR (15)  NULL,
    [Warehouse]             VARCHAR (50)  NULL
);


GO
CREATE NONCLUSTERED INDEX [CIX_CCID]
    ON [Staging].[BrandNewCandidate_POS_WA]([ConsumerCombinationID] ASC);

