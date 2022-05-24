CREATE TABLE [Staging].[RF_Backup_Derived_Customer_UnsubscribeDates] (
    [ID]              INT          IDENTITY (1, 1) NOT NULL,
    [FanID]           INT          NOT NULL,
    [UnsubscribeDate] DATE         NULL,
    [UnsubscribeType] NVARCHAR (7) NULL,
    [CampaignKey]     NVARCHAR (8) NULL
);

