CREATE TABLE [Staging].[CardTransactionAuditAction] (
    [AuditActionID] TINYINT       IDENTITY (1, 1) NOT NULL,
    [ActionDesc]    VARCHAR (100) NOT NULL,
    CONSTRAINT [PK__CardTran__53A8C1C40B679CE2] PRIMARY KEY CLUSTERED ([AuditActionID] ASC)
);

