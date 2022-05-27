CREATE TABLE [RewardBI].[CustomerActiveStatus] (
    [FanID]           INT  NOT NULL,
    [ActivatedDate]   DATE NOT NULL,
    [DeactivatedDate] DATE NULL,
    [OptedOutDate]    DATE NULL,
    CONSTRAINT [PK_RewardBI_CustomerActiveStatus] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

