CREATE TABLE [MI].[TotalBrandSpendLoadAudit] (
    [AuditID]     INT           IDENTITY (1, 1) NOT NULL,
    [AuditAction] VARCHAR (500) NOT NULL,
    [AUDITDATE]   SMALLDATETIME NOT NULL,
    CONSTRAINT [PK_MI_TotalBrandSpendLoadAudit] PRIMARY KEY CLUSTERED ([AuditID] ASC)
);

