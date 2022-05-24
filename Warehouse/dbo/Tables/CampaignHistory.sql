CREATE TABLE [dbo].[CampaignHistory] (
    [ironoffercyclesid] INT NOT NULL,
    [FanID]             INT NOT NULL,
    CONSTRAINT [PK_CampaignHistory] PRIMARY KEY CLUSTERED ([ironoffercyclesid] ASC, [FanID] ASC)
);

