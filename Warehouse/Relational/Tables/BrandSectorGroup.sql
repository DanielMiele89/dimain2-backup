CREATE TABLE [Relational].[BrandSectorGroup] (
    [SectorGroupID] TINYINT      IDENTITY (1, 1) NOT NULL,
    [GroupName]     VARCHAR (50) NULL,
    CONSTRAINT [PK_BrandSectorGroup_v2] PRIMARY KEY CLUSTERED ([SectorGroupID] ASC)
);




GO
GRANT SELECT
    ON OBJECT::[Relational].[BrandSectorGroup] TO [visa_etl_user]
    AS [dbo];

