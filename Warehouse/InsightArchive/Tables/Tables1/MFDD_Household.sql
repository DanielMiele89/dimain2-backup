CREATE TABLE [InsightArchive].[MFDD_Household] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [SourceUID]     VARCHAR (20) NOT NULL,
    [BankAccountID] INT          NOT NULL,
    [HouseholdID]   INT          NOT NULL,
    [FanID]         INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [cix_SourceUID]
    ON [InsightArchive].[MFDD_Household]([SourceUID] ASC);


GO
CREATE NONCLUSTERED INDEX [cix_HouseholdID_SourceUID]
    ON [InsightArchive].[MFDD_Household]([HouseholdID] ASC)
    INCLUDE([SourceUID]);

