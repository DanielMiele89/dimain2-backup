CREATE TABLE [Staging].[Customer_LastEmailReceived] (
    [FanID]       INT          NOT NULL,
    [SendDate]    DATETIME     NOT NULL,
    [CampaignKey] NVARCHAR (8) NOT NULL,
    [RowNo]       BIGINT       NULL
);

