CREATE TABLE [Staging].[CardTransactionLoad_Audit] (
    [AuditID]     INT      IDENTITY (1, 1) NOT NULL,
    [AuditAction] TINYINT  NOT NULL,
    [AuditStatus] TINYINT  NOT NULL,
    [AuditDate]   DATETIME NOT NULL,
    [FileID]      INT      NULL,
    CONSTRAINT [FK_CardTransactionLoadAudit_AuditAction] FOREIGN KEY ([AuditAction]) REFERENCES [Staging].[CardTransactionAuditAction] ([AuditActionID])
);

