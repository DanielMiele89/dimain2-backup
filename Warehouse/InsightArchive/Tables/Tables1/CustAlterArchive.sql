CREATE TABLE [InsightArchive].[CustAlterArchive] (
    [ID]                 INT      NOT NULL,
    [FanID]              INT      NOT NULL,
    [ActivationStatusID] TINYINT  NOT NULL,
    [ActivatedOffline]   BIT      NOT NULL,
    [StatusDate]         DATE     NOT NULL,
    [IsRBS]              BIT      NOT NULL,
    [AuditDate]          DATETIME NOT NULL
);

