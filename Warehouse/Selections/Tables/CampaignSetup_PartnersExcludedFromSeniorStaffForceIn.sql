CREATE TABLE [Selections].[CampaignSetup_PartnersExcludedFromSeniorStaffForceIn] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [PartnerID] INT  NULL,
    [StartDate] DATE NULL,
    [EndDate]   DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerID]
    ON [Selections].[CampaignSetup_PartnersExcludedFromSeniorStaffForceIn]([PartnerID] ASC);

