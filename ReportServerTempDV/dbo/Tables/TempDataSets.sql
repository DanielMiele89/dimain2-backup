CREATE TABLE [dbo].[TempDataSets] (
    [ID]     UNIQUEIDENTIFIER NOT NULL,
    [ItemID] UNIQUEIDENTIFIER NOT NULL,
    [LinkID] UNIQUEIDENTIFIER NULL,
    [Name]   NVARCHAR (260)   NOT NULL,
    CONSTRAINT [PK_TempDataSet] PRIMARY KEY NONCLUSTERED ([ID] ASC),
    CONSTRAINT [FK_DataSetItemID] FOREIGN KEY ([ItemID]) REFERENCES [dbo].[TempCatalog] ([TempCatalogID])
);




GO
CREATE CLUSTERED INDEX [IX_TempDataSet_ItemID_Name]
    ON [dbo].[TempDataSets]([ItemID] ASC, [Name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DataSetLinkID]
    ON [dbo].[TempDataSets]([LinkID] ASC);


GO
GRANT UPDATE
    ON OBJECT::[dbo].[TempDataSets] TO [RSExecRole]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[TempDataSets] TO [RSExecRole]
    AS [dbo];


GO
GRANT REFERENCES
    ON OBJECT::[dbo].[TempDataSets] TO [RSExecRole]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[TempDataSets] TO [RSExecRole]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[dbo].[TempDataSets] TO [RSExecRole]
    AS [dbo];

