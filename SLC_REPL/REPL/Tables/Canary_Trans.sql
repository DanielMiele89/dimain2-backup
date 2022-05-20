CREATE TABLE [REPL].[Canary_Trans] (
    [LastUpdate] DATETIME NOT NULL,
    CONSTRAINT [PK_Canary_Trans] PRIMARY KEY CLUSTERED ([LastUpdate] ASC)
);


GO
DENY SELECT
    ON OBJECT::[REPL].[Canary_Trans] TO [Analyst]
    AS [dbo];

