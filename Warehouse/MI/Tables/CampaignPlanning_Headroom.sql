CREATE TABLE [MI].[CampaignPlanning_Headroom] (
    [FanID]                   INT          NOT NULL,
    [PartnerNameID]           INT          NOT NULL,
    [HTMID]                   VARCHAR (6)  NULL,
    [HTM_Description]         VARCHAR (50) NULL,
    [SuperSegmentID]          VARCHAR (3)  NULL,
    [SuperSegmentDescription] VARCHAR (50) NULL,
    [Engaged]                 INT          NOT NULL
);


GO
CREATE CLUSTERED INDEX [IND_CampaignPlanning_Trigger_Partner]
    ON [MI].[CampaignPlanning_Headroom]([PartnerNameID] ASC, [FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_CampaignPlanning_Trigger_Fan]
    ON [MI].[CampaignPlanning_Headroom]([FanID] ASC) WITH (DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

