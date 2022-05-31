﻿CREATE TABLE [WilliamA].[MyRewardsDataHashed_20210806] (
    [FanID]            INT           NOT NULL,
    [Email]            VARCHAR (100) NULL,
    [FirstName]        VARCHAR (50)  NULL,
    [LastName]         VARCHAR (50)  NULL,
    [Address1]         VARCHAR (100) NULL,
    [Postcode]         VARCHAR (10)  NULL,
    [Reward_Email]     VARCHAR (64)  NULL,
    [Reward_FirstName] VARCHAR (64)  NULL,
    [Reward_LastName]  VARCHAR (64)  NULL,
    [Reward_Address1]  VARCHAR (64)  NULL,
    [Reward_Postcode]  VARCHAR (64)  NULL
);


GO
CREATE CLUSTERED INDEX [IDX_MyRewardsDataHashed_FanID]
    ON [WilliamA].[MyRewardsDataHashed_20210806]([FanID] ASC);

