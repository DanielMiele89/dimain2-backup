CREATE TABLE [MI].[CustomerActivationHistory] (
    [ID]                 INT      IDENTITY (1, 1) NOT NULL,
    [FanID]              INT      NOT NULL,
    [ActivationStatusID] TINYINT  NOT NULL,
    [ActivatedOffline]   BIT      NOT NULL,
    [StatusDate]         DATE     NOT NULL,
    [IsRBS]              BIT      NOT NULL,
    [AuditDate]          DATETIME NOT NULL,
    CONSTRAINT [PK_MI_CustomerActivationHistory] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_MI_CustomerActivationHistory_ActivationStatus] FOREIGN KEY ([ActivationStatusID]) REFERENCES [MI].[CustomerActivationHistory_Status] ([ID])
);


GO
CREATE NONCLUSTERED INDEX [ix_ActivationStatusID_FanID]
    ON [MI].[CustomerActivationHistory]([ActivationStatusID] ASC, [FanID] ASC, [IsRBS] ASC)
    INCLUDE([StatusDate]) WITH (FILLFACTOR = 80);

