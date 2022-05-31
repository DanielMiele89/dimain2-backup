﻿CREATE TABLE [ChrisN].[RewardEON_Matched] (
    [ID]               INT           NULL,
    [FanID]            INT           NOT NULL,
    [Email]            VARCHAR (100) NULL,
    [FirstName]        VARCHAR (50)  NULL,
    [LastName]         VARCHAR (50)  NULL,
    [Address1]         VARCHAR (100) NULL,
    [PostCode]         VARCHAR (10)  NULL,
    [Reward_Email]     VARCHAR (64)  NULL,
    [Reward_FirstName] VARCHAR (64)  NULL,
    [Reward_LastName]  VARCHAR (64)  NULL,
    [Reward_Address1]  VARCHAR (64)  NULL,
    [Reward_Postcode]  VARCHAR (64)  NULL,
    [EON_Email]        VARCHAR (64)  NULL,
    [EON_FirstName]    VARCHAR (64)  NULL,
    [EON_LastName]     VARCHAR (64)  NULL,
    [EON_Address1]     VARCHAR (64)  NULL,
    [EON_Postcode]     VARCHAR (64)  NULL,
    [MatchedOn]        VARCHAR (100) NULL
);

