CREATE TABLE [Staging].[CampaignPlanning_Brand_CCID] (
    [PartnerID]             SMALLINT NOT NULL,
    [ConsumerCombinationID] INT      NOT NULL
);


GO
CREATE CLUSTERED INDEX [IND]
    ON [Staging].[CampaignPlanning_Brand_CCID]([ConsumerCombinationID] ASC);

