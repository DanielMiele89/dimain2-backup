CREATE TABLE [Selections].[CampaignCode_Selections_ExistingPartnerOfferMemberships] (
    [PartnerID]   INT    NULL,
    [CompositeID] BIGINT NULL
);


GO
CREATE NONCLUSTERED INDEX [CIX_ExistingPartnerOfferMemberships_PartnerCompositeID]
    ON [Selections].[CampaignCode_Selections_ExistingPartnerOfferMemberships]([PartnerID] ASC, [CompositeID] ASC);

