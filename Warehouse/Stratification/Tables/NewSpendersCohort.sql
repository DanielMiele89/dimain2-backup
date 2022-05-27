CREATE TABLE [Stratification].[NewSpendersCohort] (
    [partnergroupID]    INT          NULL,
    [partnerId]         INT          NULL,
    [FanID]             INT          NOT NULL,
    [FirstMonth]        INT          NOT NULL,
    [Cohort]            VARCHAR (21) NOT NULL,
    [ClientServicesRef] VARCHAR (40) NULL,
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_Stratification_NewSpendersCohort] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_RVW_Stratification_NewSpendersCohort]
    ON [Stratification].[NewSpendersCohort]([FirstMonth] ASC)
    INCLUDE([partnerId], [FanID], [ClientServicesRef]);


GO
CREATE NONCLUSTERED INDEX [IX_RVW_Stratification_NewSpendersCohort_MonthlyReportHelp]
    ON [Stratification].[NewSpendersCohort]([partnerId] ASC, [FanID] ASC, [ClientServicesRef] ASC, [FirstMonth] ASC);

