CREATE TABLE [InsightArchive].[MorrisonsLaunch_MyRewardsDataHashed_20180530] (
    [FanID]                     INT           NOT NULL,
    [FirstName]                 VARCHAR (50)  NULL,
    [Lastname]                  VARCHAR (50)  NULL,
    [Address1]                  VARCHAR (100) NULL,
    [Postcode]                  VARCHAR (10)  NULL,
    [Email]                     VARCHAR (100) NULL,
    [FirstNameHashed_Reward]    VARCHAR (64)  NULL,
    [SurnameHashed_Reward]      VARCHAR (64)  NULL,
    [AddressLine1Hashed_Reward] VARCHAR (64)  NULL,
    [PostCodeHashed_Reward]     VARCHAR (64)  NULL,
    [EmailHashed_Reward]        VARCHAR (64)  NULL
);


GO
CREATE CLUSTERED INDEX [IDX_MorrisonsLaunch_Reward_Email]
    ON [InsightArchive].[MorrisonsLaunch_MyRewardsDataHashed_20180530]([EmailHashed_Reward] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

