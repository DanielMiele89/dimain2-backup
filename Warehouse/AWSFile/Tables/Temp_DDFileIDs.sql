CREATE TABLE [AWSFile].[Temp_DDFileIDs] (
    [FileID]      INT NULL,
    [StartFileID] INT NULL,
    [EndFileID]   INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [AWSFile].[Temp_DDFileIDs]([StartFileID] ASC, [FileID] ASC);

