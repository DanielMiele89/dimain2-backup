CREATE TABLE [Staging].[BrandMCC] (
    [BrandID]          INT           NULL,
    [BrandDescription] VARCHAR (30)  NULL,
    [Code]             VARCHAR (4)   NULL,
    [Description]      VARCHAR (100) NULL,
    [Category]         VARCHAR (100) NULL,
    [Group]            VARCHAR (100) NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [PK_BrandMCC]
    ON [Staging].[BrandMCC]([BrandID] ASC, [Code] ASC);

