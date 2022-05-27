CREATE TABLE [Relational].[BrandGroup] (
    [BrandGroupID]   TINYINT      IDENTITY (1, 1) NOT NULL,
    [BrandGroupName] VARCHAR (50) NULL,
    PRIMARY KEY CLUSTERED ([BrandGroupID] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_BrandGroup_BrandGroupName]
    ON [Relational].[BrandGroup]([BrandGroupName] ASC);


GO
GRANT SELECT
    ON OBJECT::[Relational].[BrandGroup] TO [visa_etl_user]
    AS [dbo];

