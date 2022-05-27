CREATE TABLE [MI].[EarnRedeemFinance_RBS_CustomerEligible] (
    [FanID]            INT     NOT NULL,
    [ActivatedDate]    DATE    NOT NULL,
    [DeactivatedDate]  DATE    NULL,
    [OptedOutDate]     DATE    NULL,
    [EarningsCleared]  MONEY   NOT NULL,
    [Redeemed]         MONEY   NOT NULL,
    [CustomerEligible] BIT     NOT NULL,
    [CustomerActive]   BIT     NOT NULL,
    [BankID]           TINYINT NULL,
    [IsRainbow]        BIT     NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_RBS_CustomerEligible] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

