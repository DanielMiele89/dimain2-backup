CREATE TABLE [SmartEmail].[TriggerEmailDailyFile_Calculated] (
    [FanID]            INT           NOT NULL,
    [LoyaltyAccount]   BIT           NOT NULL,
    [IsLoyalty]        BIT           NOT NULL,
    [IsDebit]          BIT           NOT NULL,
    [IsCredit]         BIT           NOT NULL,
    [WG]               BIT           NOT NULL,
    [FirstEarnDate]    DATE          NOT NULL,
    [FirstEarnType]    VARCHAR (100) NOT NULL,
    [FirstEarnValue]   SMALLMONEY    NOT NULL,
    [Reached5GBP]      DATE          NOT NULL,
    [Day65AccountName] VARCHAR (40)  NOT NULL,
    [Day65AccountNo]   VARCHAR (3)   NOT NULL,
    [MyRewardAccount]  VARCHAR (40)  NOT NULL,
    [Homemover]        BIT           NULL,
    [WelcomeEmailCode] VARCHAR (10)  NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

