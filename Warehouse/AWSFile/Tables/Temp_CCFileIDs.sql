CREATE TABLE [AWSFile].[Temp_CCFileIDs] (
    [FileID]      INT NULL,
    [StartFileID] INT NULL,
    [EndFileID]   INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [AWSFile].[Temp_CCFileIDs]([StartFileID] ASC, [FileID] ASC);

