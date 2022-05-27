CREATE TABLE [Relational].[NewHousehouldIDs] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [FanID]         BIGINT       NOT NULL,
    [SourceUID]     VARCHAR (20) NOT NULL,
    [BankAccountID] INT          NOT NULL,
    [HouseholdID]   INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CIX_SourceUID]
    ON [Relational].[NewHousehouldIDs]([SourceUID] ASC);


GO
CREATE NONCLUSTERED INDEX [CIX_HouseholdID_SourceUID]
    ON [Relational].[NewHousehouldIDs]([HouseholdID] ASC)
    INCLUDE([SourceUID]);

