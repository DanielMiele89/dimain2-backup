CREATE TABLE [Prototype].[CampaignPlanning_HeatMap] (
    [FanID]         INT NOT NULL,
    [PartnerNameID] INT NOT NULL,
    [HeatmapID]     INT NULL,
    [Engaged]       INT NULL
);


GO
CREATE CLUSTERED INDEX [IDX_HM_PIDFID]
    ON [Prototype].[CampaignPlanning_HeatMap]([PartnerNameID] ASC, [FanID] ASC);

