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


GO
GRANT UPDATE
    ON OBJECT::[Staging].[BrandNewCandidate_DD] TO [New_Branding]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Staging].[BrandNewCandidate_DD] TO [New_Branding]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Staging].[BrandNewCandidate_DD] TO [New_Branding]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[Staging].[BrandNewCandidate_DD] TO [New_Branding]
    AS [dbo];


GO
GRANT ALTER
    ON OBJECT::[Staging].[BrandNewCandidate_DD] TO [New_Branding]
    AS [dbo];

