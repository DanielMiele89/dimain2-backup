CREATE TABLE [MI].[CampaignPlanning_Brands] (
    [PartnerNameID]         INT NOT NULL,
    [ConsumerCombinationID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [IND]
    ON [MI].[CampaignPlanning_Brands]([ConsumerCombinationID] ASC);

