CREATE TABLE [REPL].[Canary_Fan] (
    [LastUpdate] DATETIME NOT NULL,
    CONSTRAINT [PK_Canary_Fan] PRIMARY KEY CLUSTERED ([LastUpdate] ASC)
);


GO
DENY SELECT
    ON OBJECT::[REPL].[Canary_Fan] TO [Analyst]
    AS [dbo];

