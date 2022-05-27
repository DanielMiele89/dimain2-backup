CREATE TABLE [MI].[MarketingEmail_ChangeLog] (
    [ID]                        INT      IDENTITY (1, 1) NOT NULL,
    [FanID]                     INT      NOT NULL,
    [MarketingEmailUnsubscribe] BIT      NOT NULL,
    [EventDate]                 DATE     NOT NULL,
    [AuditDate]                 DATETIME NOT NULL,
    CONSTRAINT [PK_MI_MarketingEmail_ChangeLog] PRIMARY KEY CLUSTERED ([ID] ASC)
);

