CREATE TABLE [dbo].[Pan] (
    [ID]              INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [AffiliateID]     INT      NOT NULL,
    [UserID]          INT      NOT NULL,
    [AdditionDate]    DATETIME NOT NULL,
    [RemovalDate]     DATETIME NULL,
    [DuplicationDate] DATETIME NULL,
    [DuplicatePanID]  INT      NULL,
    [CompositeID]     BIGINT   NULL,
    [PaymentCardID]   INT      NULL,
    CONSTRAINT [PK_Pan] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 95)
);


GO
CREATE NONCLUSTERED INDEX [ix_AdditionDate_RemovalDate]
    ON [dbo].[Pan]([AdditionDate] ASC, [RemovalDate] ASC)
    INCLUDE([ID], [CompositeID], [PaymentCardID], [DuplicationDate]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_CompositeID]
    ON [dbo].[Pan]([CompositeID] ASC, [AdditionDate] ASC, [RemovalDate] ASC)
    INCLUDE([DuplicationDate], [PaymentCardID], [UserID]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_PaymentCardID]
    ON [dbo].[Pan]([PaymentCardID] ASC)
    INCLUDE([AdditionDate], [DuplicationDate], [CompositeID], [RemovalDate]) WITH (FILLFACTOR = 80)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_RemovalDate]
    ON [dbo].[Pan]([RemovalDate] ASC, [CompositeID] ASC)
    INCLUDE([AdditionDate], [DuplicationDate], [PaymentCardID]) WITH (FILLFACTOR = 75)
    ON [SLC_REPL_Indexes];


GO
GRANT SELECT
    ON OBJECT::[dbo].[Pan] TO [Analyst]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[Pan] TO [PII_Removed]
    AS [dbo];

