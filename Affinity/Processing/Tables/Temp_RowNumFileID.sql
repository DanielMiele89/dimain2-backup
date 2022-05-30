CREATE TABLE [Processing].[Temp_RowNumFileID] (
    [FileID] INT NULL,
    [RowNum] INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [Processing].[Temp_RowNumFileID]([FileID] ASC, [RowNum] ASC);

