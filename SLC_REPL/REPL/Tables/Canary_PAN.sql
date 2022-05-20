CREATE TABLE [REPL].[Canary_PAN] (
    [LastUpdate] DATETIME NOT NULL,
    CONSTRAINT [PK_Canary_PAN] PRIMARY KEY CLUSTERED ([LastUpdate] ASC)
);


GO
DENY SELECT
    ON OBJECT::[REPL].[Canary_PAN] TO [Analyst]
    AS [dbo];

