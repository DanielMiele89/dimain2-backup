CREATE TABLE [Staging].[BrandNewCandidate_DD] (
    [ConsumerCombinationID_DD] BIGINT        NULL,
    [OIN]                      INT           NULL,
    [BrandID]                  INT           NULL,
    [Narrative_RBS]            VARCHAR (250) NULL,
    [Narrative_VF]             VARCHAR (250) NULL
);


GO
CREATE NONCLUSTERED INDEX [CIX_CCID]
    ON [Staging].[BrandNewCandidate_DD]([ConsumerCombinationID_DD] ASC);

