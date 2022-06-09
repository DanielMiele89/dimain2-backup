CREATE TABLE [msqta].[MetaData] (
    [Property] NVARCHAR (50)  NOT NULL,
    [Value]    NVARCHAR (MAX) NOT NULL,
    UNIQUE NONCLUSTERED ([Property] ASC)
);

