CREATE TABLE [InsightArchive].[WG_Codes] (
    [RBS Sort Code]         FLOAT (53)     NULL,
    [Revised RBS Sort Code] NVARCHAR (255) NULL,
    [Name]                  NVARCHAR (255) NULL,
    [Label]                 NVARCHAR (255) NULL,
    [Comments]              NVARCHAR (255) NULL
);


GO
CREATE CLUSTERED INDEX [ix_WG_Codes_SortCode]
    ON [InsightArchive].[WG_Codes]([RBS Sort Code] ASC);

