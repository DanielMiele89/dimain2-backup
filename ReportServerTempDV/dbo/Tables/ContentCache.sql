CREATE TABLE [dbo].[ContentCache] (
    [ContentCacheID]  BIGINT           IDENTITY (1, 1) NOT NULL,
    [CatalogItemID]   UNIQUEIDENTIFIER NOT NULL,
    [CreatedDate]     DATETIME         NOT NULL,
    [ParamsHash]      INT              NULL,
    [EffectiveParams] NVARCHAR (MAX)   NULL,
    [ContentType]     NVARCHAR (256)   NULL,
    [ExpirationDate]  DATETIME         NOT NULL,
    [Version]         SMALLINT         NULL,
    [Content]         VARBINARY (MAX)  NULL,
    CONSTRAINT [PK_ContentCache] PRIMARY KEY NONCLUSTERED ([ContentCacheID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ContentCache]
    ON [dbo].[ContentCache]([CatalogItemID] ASC, [ParamsHash] ASC, [ContentType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ContentCache_ExpirationDate]
    ON [dbo].[ContentCache]([ExpirationDate] ASC);

