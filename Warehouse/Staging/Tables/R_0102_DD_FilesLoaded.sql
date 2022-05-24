CREATE TABLE [Staging].[R_0102_DD_FilesLoaded] (
    [FileID]          INT            IDENTITY (1, 1) NOT NULL,
    [FileName]        VARCHAR (256)  NOT NULL,
    [FileType]        VARCHAR (68)   NOT NULL,
    [InDate]          DATETIME       NOT NULL,
    [InStatus]        BIT            NULL,
    [InMessage]       VARCHAR (1024) NULL,
    [StoredProcedure] VARCHAR (31)   NOT NULL
);

