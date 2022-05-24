CREATE TABLE [Prototype].[RandomBase] (
    [CINID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [ix_CINID]
    ON [Prototype].[RandomBase]([CINID] ASC);

