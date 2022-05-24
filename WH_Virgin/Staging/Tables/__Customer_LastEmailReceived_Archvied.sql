CREATE TABLE [Staging].[__Customer_LastEmailReceived_Archvied] (
    [FanID]       INT          NOT NULL,
    [SendDate]    DATETIME     NOT NULL,
    [CampaignKey] NVARCHAR (8) NOT NULL,
    [RowNo]       BIGINT       NULL
);

