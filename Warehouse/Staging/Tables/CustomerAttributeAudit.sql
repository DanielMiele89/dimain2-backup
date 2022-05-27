CREATE TABLE [Staging].[CustomerAttributeAudit] (
    [AuditID]   INT           IDENTITY (1, 1) NOT NULL,
    [QueryDesc] VARCHAR (50)  NOT NULL,
    [AuditDate] SMALLDATETIME DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([AuditID] ASC)
);

