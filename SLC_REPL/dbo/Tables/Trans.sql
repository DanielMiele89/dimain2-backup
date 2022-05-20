CREATE TABLE [dbo].[Trans] (
    [ID]                      INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [TypeID]                  TINYINT        NOT NULL,
    [FanID]                   INT            NOT NULL,
    [ItemID]                  INT            NOT NULL,
    [Quantity]                INT            NOT NULL,
    [Points]                  INT            NOT NULL,
    [Commission]              FLOAT (53)     NOT NULL,
    [Price]                   SMALLMONEY     NOT NULL,
    [VAT]                     INT            NOT NULL,
    [ActivationDays]          INT            NOT NULL,
    [Date]                    DATETIME       NOT NULL,
    [Processed]               INT            NOT NULL,
    [ProcessDate]             DATETIME       NOT NULL,
    [CommissionEarned]        MONEY          NOT NULL,
    [VatRate]                 FLOAT (53)     NOT NULL,
    [TransactionCost]         SMALLMONEY     NOT NULL,
    [VectorID]                TINYINT        NULL,
    [VectorMajorID]           INT            NULL,
    [VectorMinorID]           INT            NULL,
    [Option]                  NVARCHAR (100) NULL,
    [PanID]                   INT            NULL,
    [MatchID]                 INT            NULL,
    [ClubCash]                SMALLMONEY     NULL,
    [PartnerCommissionRuleID] INT            NULL,
    [IssuerBankAccountID]     INT            NULL,
    [DirectDebitOriginatorID] INT            NULL,
    CONSTRAINT [PK_Trans_ID] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 95)
);


GO
CREATE NONCLUSTERED INDEX [ix_ACBA]
    ON [dbo].[Trans]([ProcessDate] ASC, [TypeID] ASC, [ItemID] ASC)
    INCLUDE([VectorMajorID], [VectorMinorID], [PanID], [FanID], [DirectDebitOriginatorID], [ActivationDays], [ClubCash], [Price], [Date], [MatchID]) WITH (FILLFACTOR = 80)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_MatchID]
    ON [dbo].[Trans]([MatchID] ASC)
    INCLUDE([FanID], [ActivationDays], [ClubCash], [TypeID], [PartnerCommissionRuleID], [CommissionEarned]) WITH (FILLFACTOR = 80)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_ACPPF]
    ON [dbo].[Trans]([FanID] ASC, [TypeID] ASC, [ItemID] ASC)
    INCLUDE([Points], [ActivationDays], [Date], [ClubCash]) WITH (FILLFACTOR = 80)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_ItemID_ID]
    ON [dbo].[Trans]([ItemID] ASC, [ID] ASC) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_PartnerCommissionRuleID_MatchID]
    ON [dbo].[Trans]([PartnerCommissionRuleID] ASC, [MatchID] ASC)
    INCLUDE([TypeID], [FanID], [ClubCash]) WITH (FILLFACTOR = 80)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_TypeID_ID]
    ON [dbo].[Trans]([TypeID] ASC, [ID] ASC)
    INCLUDE([Price], [FanID], [ItemID], [ActivationDays], [ProcessDate], [ClubCash]) WITH (FILLFACTOR = 80)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_TypeID_ItemID]
    ON [dbo].[Trans]([TypeID] ASC, [ItemID] ASC, [FanID] ASC)
    INCLUDE([Date], [Price], [Option], [Points], [ClubCash], [ProcessDate]) WITH (FILLFACTOR = 80)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_TypeID_VectorMajorID]
    ON [dbo].[Trans]([TypeID] ASC, [VectorMajorID] ASC, [VectorMinorID] ASC, [ItemID] ASC)
    INCLUDE([ClubCash]) WITH (FILLFACTOR = 80)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_FirstTrans]
    ON [dbo].[Trans]([FanID] ASC, [TypeID] ASC, [ItemID] ASC, [ProcessDate] ASC) WITH (FILLFACTOR = 80)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_TypeID_Date]
    ON [dbo].[Trans]([TypeID] ASC, [Date] ASC)
    INCLUDE([FanID], [ClubCash], [IssuerBankAccountID])
    ON [SLC_REPL_Indexes];


GO

create TRIGGER [dbo].[TriggerTransDelete] on [dbo].[Trans]
AFTER DELETE
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO dbo.Trans_Changes (TransID, [Action])
	SELECT 
		d.ID, 
		[Action] = 'I'
	FROM deleted d 
END
GO
CREATE TRIGGER TriggerTransUpdate on dbo.Trans
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO dbo.Trans_Changes (TransID, [Action])
	SELECT 
		i.ID, 
		[Action] = 'U'
	FROM inserted i 
END

GO

CREATE TRIGGER TriggerTransInsert on dbo.Trans
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO dbo.Trans_Changes (TransID, [Action])
	SELECT 
		i.ID, 
		[Action] = 'I'
	FROM inserted i 
END
GO
GRANT SELECT
    ON OBJECT::[dbo].[Trans] TO [Analyst]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[Trans] TO [PII_Removed]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[Trans] TO [Process_AWS_SpendEarn]
    AS [dbo];

