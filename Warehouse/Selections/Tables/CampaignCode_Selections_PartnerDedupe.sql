CREATE TABLE [Selections].[CampaignCode_Selections_PartnerDedupe] (
    [ID]          INT    IDENTITY (1, 1) NOT NULL,
    [PartnerID]   INT    NULL,
    [CompositeID] BIGINT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerID]
    ON [Selections].[CampaignCode_Selections_PartnerDedupe]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CompositeID]
    ON [Selections].[CampaignCode_Selections_PartnerDedupe]([CompositeID] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = ROW);

