CREATE TABLE [MI].[EarnRedeemFinance_CustomerEligible] (
    [FanID]            INT     NOT NULL,
    [ActivatedDate]    DATE    NOT NULL,
    [DeactivatedDate]  DATE    NULL,
    [OptedOutDate]     DATE    NULL,
    [EarningsCleared]  MONEY   NOT NULL,
    [Redeemed]         MONEY   NOT NULL,
    [CustomerEligible] BIT     NOT NULL,
    [CustomerActive]   BIT     NOT NULL,
    [BankID]           TINYINT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_CustomerEligible] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

