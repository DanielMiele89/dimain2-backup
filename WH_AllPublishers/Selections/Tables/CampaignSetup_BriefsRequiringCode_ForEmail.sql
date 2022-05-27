CREATE TABLE [Selections].[CampaignSetup_BriefsRequiringCode_ForEmail] (
    [RetailerName]                        VARCHAR (50)  NULL,
    [CampaignCode]                        VARCHAR (50)  NULL,
    [CampaignName]                        VARCHAR (100) NULL,
    [CampaignStartDate]                   DATE          NULL,
    [BespokeCampaign_Analyst]             VARCHAR (50)  NULL,
    [PreviousCampaignToCopyTargetingFrom] VARCHAR (50)  NULL,
    [ActionRequired]                      VARCHAR (27)  NULL
);


GO
CREATE CLUSTERED INDEX [CIX_All]
    ON [Selections].[CampaignSetup_BriefsRequiringCode_ForEmail]([CampaignStartDate] ASC, [CampaignCode] ASC) WITH (FILLFACTOR = 90);

