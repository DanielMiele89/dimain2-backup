CREATE TABLE [Staging].[BrandNewCandidate_POS] (
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
    ON [Staging].[BrandNewCandidate_POS]([ConsumerCombinationID] ASC);


GO
GRANT UPDATE
    ON OBJECT::[Staging].[BrandNewCandidate_POS] TO [New_Branding]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Staging].[BrandNewCandidate_POS] TO [New_Branding]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Staging].[BrandNewCandidate_POS] TO [New_Branding]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[Staging].[BrandNewCandidate_POS] TO [New_Branding]
    AS [dbo];


GO
GRANT ALTER
    ON OBJECT::[Staging].[BrandNewCandidate_POS] TO [New_Branding]
    AS [dbo];

