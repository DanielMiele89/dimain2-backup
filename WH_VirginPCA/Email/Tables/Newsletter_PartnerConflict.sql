CREATE TABLE [Email].[Newsletter_PartnerConflict] (
    [RuleID]                   TINYINT    NOT NULL,
    [RuleTypeID]               TINYINT    NOT NULL,
    [PartnerID]                INT        NOT NULL,
    [PercentageOfCustomers]    FLOAT (53) NULL,
    [MaxMembershipsCount]      TINYINT    NULL,
    [RequiredMembershipsCount] TINYINT    NULL,
    [PartnerToRemove]          BIT        NULL,
    [ExecutionOrder]           INT        NULL,
    [StartDate]                DATE       NULL,
    [EndDate]                  DATE       NULL,
    [LiveRule]                 INT        NULL
);

