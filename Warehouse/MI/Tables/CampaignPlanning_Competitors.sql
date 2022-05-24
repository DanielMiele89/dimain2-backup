CREATE TABLE [MI].[CampaignPlanning_Competitors] (
    [PartnerID]             INT           NULL,
    [PartnerName]           VARCHAR (100) NOT NULL,
    [ConsumerCombinationID] INT           NOT NULL
);


GO
CREATE CLUSTERED INDEX [IND]
    ON [MI].[CampaignPlanning_Competitors]([ConsumerCombinationID] ASC);

