CREATE TABLE [Selections].[CampaignExecution_TableNames] (
    [TableID]           INT           IDENTITY (1, 1) NOT NULL,
    [TableName]         VARCHAR (200) NULL,
    [ClientServicesRef] VARCHAR (25)  NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_NominatedOfferMember_TableNames_TableName]
    ON [Selections].[CampaignExecution_TableNames]([TableID] ASC);


GO
CREATE NONCLUSTERED INDEX [CIX_NominatedOfferMember_TableNames_TableID]
    ON [Selections].[CampaignExecution_TableNames]([TableID] ASC);

