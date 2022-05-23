CREATE TABLE [REPL].[Canary_PaymentCard] (
    [LastUpdate] DATETIME NOT NULL,
    CONSTRAINT [PK_Canary_PaymentCard] PRIMARY KEY CLUSTERED ([LastUpdate] ASC)
);


GO
DENY SELECT
    ON OBJECT::[REPL].[Canary_PaymentCard] TO [Analyst]
    AS [dbo];

