CREATE TABLE [MI].[EarnRedeemFinance_CrossCheck_AdditionalEarnings] (
    [ID]            INT   IDENTITY (1, 1) NOT NULL,
    [EarnMonthDate] DATE  NOT NULL,
    [Earnings]      MONEY NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_CrossCheck_AdditionalEarnings] PRIMARY KEY CLUSTERED ([ID] ASC)
);

