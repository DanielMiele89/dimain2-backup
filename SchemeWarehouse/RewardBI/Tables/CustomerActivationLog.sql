CREATE TABLE [RewardBI].[CustomerActivationLog] (
    [ID]                 INT      IDENTITY (1, 1) NOT NULL,
    [FanID]              INT      NOT NULL,
    [ActivationStatusID] TINYINT  NOT NULL,
    [StatusDate]         DATE     NOT NULL,
    [AuditDate]          DATETIME NOT NULL,
    CONSTRAINT [PK_RewardBI_CustomerActivationLog] PRIMARY KEY CLUSTERED ([ID] ASC)
);

