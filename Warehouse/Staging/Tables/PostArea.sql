CREATE TABLE [Staging].[PostArea] (
    [PostAreaCode] VARCHAR (2)  NOT NULL,
    [Region]       VARCHAR (30) NULL,
    CONSTRAINT [PK_PostArea] PRIMARY KEY CLUSTERED ([PostAreaCode] ASC)
);

