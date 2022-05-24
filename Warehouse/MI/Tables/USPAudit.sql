CREATE TABLE [MI].[USPAudit] (
    [AuditID]     INT           IDENTITY (1, 1) NOT NULL,
    [AuditDate]   DATETIME      CONSTRAINT [DF_MI_USPAudit_AuditDate] DEFAULT (getdate()) NOT NULL,
    [AuditAction] VARCHAR (500) NOT NULL,
    CONSTRAINT [PK_MI_USPAudit] PRIMARY KEY CLUSTERED ([AuditID] ASC)
);

