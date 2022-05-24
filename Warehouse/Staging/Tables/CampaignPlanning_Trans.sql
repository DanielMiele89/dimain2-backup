CREATE TABLE [Staging].[CampaignPlanning_Trans] (
    [FanID]     INT              NOT NULL,
    [PartnerID] SMALLINT         NOT NULL,
    [Value1W]   NUMERIC (33, 16) NULL,
    [Trans1W]   NUMERIC (24, 12) NULL
);


GO
CREATE CLUSTERED INDEX [IDX_C]
    ON [Staging].[CampaignPlanning_Trans]([PartnerID] ASC, [FanID] ASC);

