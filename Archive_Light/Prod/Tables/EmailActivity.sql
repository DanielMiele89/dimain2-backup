CREATE TABLE [Prod].[EmailActivity] (
    [ID]              INT      IDENTITY (1, 1) NOT NULL,
    [EmailCampaignID] INT      NOT NULL,
    [FanID]           INT      NOT NULL,
    [DeliveryDate]    DATETIME NOT NULL,
    [OpenDate]        DATETIME NULL,
    [ClickDate]       DATETIME NULL,
    [UnsubscribeDate] DATETIME NULL,
    [HardBounceDate]  DATETIME NULL,
    CONSTRAINT [PK_EmailActivity] PRIMARY KEY CLUSTERED ([ID] ASC)
);

