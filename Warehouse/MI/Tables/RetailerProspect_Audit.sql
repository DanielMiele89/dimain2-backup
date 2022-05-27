CREATE TABLE [MI].[RetailerProspect_Audit] (
    [ID]          INT          IDENTITY (1, 1) NOT NULL,
    [AuditAction] VARCHAR (50) NOT NULL,
    [AuditDate]   DATETIME     CONSTRAINT [DF_MI_RetailerProspect_Audit_AuditDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_MI_RetailerProspect_Audit] PRIMARY KEY CLUSTERED ([ID] ASC)
);

