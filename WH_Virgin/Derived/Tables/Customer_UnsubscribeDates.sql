CREATE TABLE [Derived].[Customer_UnsubscribeDates] (
    [ID]              INT          IDENTITY (1, 1) NOT NULL,
    [FanID]           INT          NOT NULL,
    [UnsubscribeDate] DATE         NULL,
    [UnsubscribeType] NVARCHAR (7) NULL,
    [CampaignKey]     NVARCHAR (8) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_CUD]
    ON [Derived].[Customer_UnsubscribeDates]([ID] ASC);

