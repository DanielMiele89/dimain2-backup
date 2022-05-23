CREATE TABLE [dbo].[NobleFiles] (
    [ID]        INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [FileName]  VARCHAR (256)  NOT NULL,
    [FileType]  VARCHAR (68)   NOT NULL,
    [InDate]    DATETIME       NOT NULL,
    [InStatus]  BIT            NULL,
    [InMessage] VARCHAR (1024) NULL,
    CONSTRAINT [PK_NobleFiles] PRIMARY KEY CLUSTERED ([ID] ASC)
);

