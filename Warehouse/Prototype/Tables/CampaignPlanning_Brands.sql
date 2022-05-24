CREATE TABLE [Prototype].[CampaignPlanning_Brands] (
    [PartnerNameID]         INT NOT NULL,
    [ConsumerCombinationID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [IND]
    ON [Prototype].[CampaignPlanning_Brands]([ConsumerCombinationID] ASC);

