CREATE TABLE [MI].[EarnRedeemFinance_CrossCheck_CashbackAwards] (
    [ID]             INT   IDENTITY (1, 1) NOT NULL,
    [AwardMonthDate] DATE  NOT NULL,
    [Awards]         MONEY NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_CrossCheck_CashbackAwards] PRIMARY KEY CLUSTERED ([ID] ASC)
);

