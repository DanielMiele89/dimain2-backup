CREATE TABLE [REPL].[Canary_Comments] (
    [LastUpdate] DATETIME NOT NULL,
    CONSTRAINT [PK_Canary_Comments] PRIMARY KEY CLUSTERED ([LastUpdate] ASC)
);


GO
DENY SELECT
    ON OBJECT::[REPL].[Canary_Comments] TO [Analyst]
    AS [dbo];

