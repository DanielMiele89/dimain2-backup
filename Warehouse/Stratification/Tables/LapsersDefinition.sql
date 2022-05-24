CREATE TABLE [Stratification].[LapsersDefinition] (
    [PartnerGroupID] INT  NULL,
    [PartnerID]      INT  NULL,
    [Months]         INT  NULL,
    [UpdatedDate]    DATE DEFAULT (getdate()) NULL,
    CONSTRAINT [UN_Partner] UNIQUE NONCLUSTERED ([PartnerGroupID] ASC, [PartnerID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IND_GID]
    ON [Stratification].[LapsersDefinition]([PartnerGroupID] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_PID]
    ON [Stratification].[LapsersDefinition]([PartnerID] ASC);

