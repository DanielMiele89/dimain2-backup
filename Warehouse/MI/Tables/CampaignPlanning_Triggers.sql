CREATE TABLE [MI].[CampaignPlanning_Triggers] (
    [Engaged]             INT           NULL,
    [FanID]               INT           NOT NULL,
    [Triggerid]           VARCHAR (6)   NULL,
    [Trigger_description] NVARCHAR (50) NULL,
    [PartnerNameID]       INT           NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IND_CampaignPlanning_Trigger_Fan]
    ON [MI].[CampaignPlanning_Triggers]([FanID] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE);


GO
CREATE CLUSTERED INDEX [IND_CampaignPlanning_Trigger_Partner]
    ON [MI].[CampaignPlanning_Triggers]([PartnerNameID] ASC, [FanID] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE);

