CREATE TABLE [Derived].[CampaignFansVirgin] (
    [CampaignKey] NVARCHAR (8) NOT NULL,
    [TotalFans]   INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([CampaignKey] ASC) WITH (FILLFACTOR = 70)
);

