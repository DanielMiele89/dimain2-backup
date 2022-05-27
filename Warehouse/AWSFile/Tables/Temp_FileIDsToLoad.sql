CREATE TABLE [AWSFile].[Temp_FileIDsToLoad] (
    [StartFileID] INT NULL,
    [EndFileID]   INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [AWSFile].[Temp_FileIDsToLoad]([StartFileID] DESC);

