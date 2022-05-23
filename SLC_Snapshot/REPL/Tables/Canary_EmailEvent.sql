CREATE TABLE [REPL].[Canary_EmailEvent] (
    [LastUpdate] DATETIME NOT NULL,
    CONSTRAINT [PK_Canary_EmailEvent] PRIMARY KEY CLUSTERED ([LastUpdate] ASC)
);


GO
DENY SELECT
    ON OBJECT::[REPL].[Canary_EmailEvent] TO [Analyst]
    AS [dbo];

