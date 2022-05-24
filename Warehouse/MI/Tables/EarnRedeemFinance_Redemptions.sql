CREATE TABLE [MI].[EarnRedeemFinance_Redemptions] (
    [ID]               INT   IDENTITY (1, 1) NOT NULL,
    [FanID]            INT   NOT NULL,
    [RedeemDate]       DATE  NOT NULL,
    [RedemptionAmount] MONEY NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_Redemptions] PRIMARY KEY CLUSTERED ([ID] ASC)
);

