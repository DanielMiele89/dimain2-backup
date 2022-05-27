CREATE TABLE [Staging].[BrandMatch_DD] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]   INT          NULL,
    [Narrative] VARCHAR (20) NULL
);




GO
GRANT UPDATE
    ON OBJECT::[Staging].[BrandMatch_DD] TO [New_Branding]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Staging].[BrandMatch_DD] TO [New_Branding]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Staging].[BrandMatch_DD] TO [New_Branding]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[Staging].[BrandMatch_DD] TO [New_Branding]
    AS [dbo];

