CREATE TABLE [MI].[EarnRedeemFinance_CrossCheck_Redemptions] (
    [ID]              INT   IDENTITY (1, 1) NOT NULL,
    [RedeemMonthDate] DATE  NOT NULL,
    [Redemption]      MONEY NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_CrossCheck_Earnings] PRIMARY KEY CLUSTERED ([ID] ASC)
);

