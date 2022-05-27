CREATE TABLE [Staging].[CampaignPlanning_SeasonalTrans] (
    [PartnerID]       INT        NOT NULL,
    [TransactionWeek] DATE       NOT NULL,
    [Value]           FLOAT (53) NULL
);


GO
CREATE CLUSTERED INDEX [IDX_PT]
    ON [Staging].[CampaignPlanning_SeasonalTrans]([PartnerID] ASC, [TransactionWeek] ASC);

