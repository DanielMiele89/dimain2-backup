CREATE TABLE [MI].[CustomerActivation_ChangeLog] (
    [ID]                 INT      IDENTITY (1, 1) NOT NULL,
    [FanID]              INT      NOT NULL,
    [ActivationStatusID] TINYINT  NOT NULL,
    [AuditDate]          DATETIME NOT NULL,
    CONSTRAINT [PK_MI_CustomerActivation_ChangeLog] PRIMARY KEY CLUSTERED ([ID] ASC)
);

