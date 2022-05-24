CREATE TABLE [Relational].[PostArea] (
    [PostAreaCode] VARCHAR (2)  NOT NULL,
    [Region]       VARCHAR (30) NOT NULL,
    CONSTRAINT [PK_PostArea] PRIMARY KEY NONCLUSTERED ([PostAreaCode] ASC)
);


GO
CREATE CLUSTERED INDEX [i_PostAreaCode]
    ON [Relational].[PostArea]([PostAreaCode] ASC);

