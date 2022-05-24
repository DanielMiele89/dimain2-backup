CREATE TABLE [AWSFile].[Temp_FileIDs] (
    [FileID]      INT NULL,
    [StartFileID] INT NULL,
    [EndFileID]   INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [AWSFile].[Temp_FileIDs]([StartFileID] ASC, [FileID] ASC);

