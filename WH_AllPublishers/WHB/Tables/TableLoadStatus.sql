CREATE TABLE [WHB].[TableLoadStatus] (
    [LoadedID]     INT IDENTITY (1, 1) NOT NULL,
    [SourceTypeID] INT NOT NULL,
    [isLoaded]     BIT NOT NULL,
    PRIMARY KEY CLUSTERED ([LoadedID] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNIX_SourceTypeID]
    ON [WHB].[TableLoadStatus]([SourceTypeID] ASC);

