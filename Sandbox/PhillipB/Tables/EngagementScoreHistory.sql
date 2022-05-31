CREATE TABLE [PhillipB].[EngagementScoreHistory] (
    [FanID]                  INT           NULL,
    [AccountSegmentation]    VARCHAR (255) NULL,
    [NomineeStatus]          INT           NULL,
    [ScoreMonth]             DATE          NULL,
    [CurrentEmailPermission] INT           NULL,
    [HasLoggedIn]            INT           NULL,
    [HasRedeemed]            INT           NULL,
    [HasTakenMerchant]       INT           NULL,
    [CardType]               INT           NULL,
    [AvgMerchantTrans]       FLOAT (53)    NULL,
    [AvgBehaviourReward]     FLOAT (53)    NULL,
    [AvgDDReward]            FLOAT (53)    NULL,
    [AvgLogIns]              FLOAT (53)    NULL,
    [AvgMultipleLogins]      FLOAT (53)    NULL,
    [AvgRedemptions]         FLOAT (53)    NULL,
    [AvgCashRedemptions]     FLOAT (53)    NULL,
    [AvgCharityRedemptions]  FLOAT (53)    NULL,
    [AvgTradeUpRedemptions]  FLOAT (53)    NULL
);

