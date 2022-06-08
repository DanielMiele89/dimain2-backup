CREATE TABLE [dbo].[TempCatalog] (
    [EditSessionID]           VARCHAR (32)     NOT NULL,
    [TempCatalogID]           UNIQUEIDENTIFIER NOT NULL,
    [ContextPath]             NVARCHAR (425)   NOT NULL,
    [Name]                    NVARCHAR (425)   NOT NULL,
    [Content]                 VARBINARY (MAX)  NULL,
    [Description]             NVARCHAR (MAX)   NULL,
    [Intermediate]            UNIQUEIDENTIFIER NULL,
    [IntermediateIsPermanent] BIT              DEFAULT ((0)) NOT NULL,
    [Property]                NVARCHAR (MAX)   NULL,
    [Parameter]               NVARCHAR (MAX)   NULL,
    [OwnerID]                 UNIQUEIDENTIFIER NOT NULL,
    [CreationTime]            DATETIME         NOT NULL,
    [ExpirationTime]          DATETIME         NOT NULL,
    [DataCacheHash]           VARBINARY (64)   NULL,
    CONSTRAINT [PK_TempCatalog] PRIMARY KEY CLUSTERED ([EditSessionID] ASC, [ContextPath] ASC),
    CONSTRAINT [UNIQ_TempCatalogID] UNIQUE NONCLUSTERED ([TempCatalogID] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_Cleanup]
    ON [dbo].[TempCatalog]([ExpirationTime] ASC);


GO
GRANT UPDATE
    ON OBJECT::[dbo].[TempCatalog] TO [RSExecRole]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[TempCatalog] TO [RSExecRole]
    AS [dbo];


GO
GRANT REFERENCES
    ON OBJECT::[dbo].[TempCatalog] TO [RSExecRole]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[TempCatalog] TO [RSExecRole]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[dbo].[TempCatalog] TO [RSExecRole]
    AS [dbo];

