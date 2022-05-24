CREATE TABLE [Prototype].[CampaignPlanning_Partners] (
    [PartnerID]     INT           NULL,
    [BrandID]       INT           NULL,
    [PartnerName]   VARCHAR (100) NULL,
    [PartnerNameID] INT           NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IND_Partner_PartnerID]
    ON [Prototype].[CampaignPlanning_Partners]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_Partner_BrandID]
    ON [Prototype].[CampaignPlanning_Partners]([BrandID] ASC);


GO
CREATE CLUSTERED INDEX [IND_Partner_Partner]
    ON [Prototype].[CampaignPlanning_Partners]([PartnerNameID] ASC);

