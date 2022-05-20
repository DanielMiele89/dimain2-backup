CREATE TABLE [dbo].[IssuerCustomer] (
    [ID]        INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [IssuerID]  INT          NOT NULL,
    [SourceUID] VARCHAR (20) NOT NULL,
    [Date]      DATETIME     NOT NULL,
    CONSTRAINT [PK_IssuerCustomer] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [dbo].[IssuerCustomer]([IssuerID] ASC, [SourceUID] ASC)
    INCLUDE([ID]) WITH (FILLFACTOR = 75)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [sn_Stuff01]
    ON [dbo].[IssuerCustomer]([SourceUID] ASC)
    INCLUDE([ID], [IssuerID]) WITH (FILLFACTOR = 75)
    ON [SLC_REPL_Indexes];


GO
GRANT SELECT
    ON OBJECT::[dbo].[IssuerCustomer] TO [Analyst]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[IssuerCustomer] TO [PII_Removed]
    AS [dbo];

