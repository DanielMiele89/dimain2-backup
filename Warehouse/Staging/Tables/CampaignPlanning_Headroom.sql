CREATE TABLE [Staging].[CampaignPlanning_Headroom] (
    [FanID]     INT      NOT NULL,
    [HTMID]     TINYINT  NULL,
    [PartnerID] SMALLINT NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IND_HTMID]
    ON [Staging].[CampaignPlanning_Headroom]([HTMID] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_PID]
    ON [Staging].[CampaignPlanning_Headroom]([PartnerID] ASC);


GO
CREATE CLUSTERED INDEX [IND_FP]
    ON [Staging].[CampaignPlanning_Headroom]([FanID] ASC);

