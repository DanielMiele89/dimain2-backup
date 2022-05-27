CREATE TABLE [Staging].[CustomerJourney_MOTWeekNos] (
    [FanID]       INT          NULL,
    [MOT1_WeekNo] TINYINT      NULL,
    [MOT1_Cycles] TINYINT      NULL,
    [MOT2_WeekNo] TINYINT      NULL,
    [MOT2_Cycles] TINYINT      NULL,
    [MOT3_WeekNo] TINYINT      NULL,
    [CampaignKey] NVARCHAR (8) NULL,
    [ID]          INT          IDENTITY (1, 1) NOT NULL,
    UNIQUE NONCLUSTERED ([FanID] ASC) WITH (FILLFACTOR = 80)
);

