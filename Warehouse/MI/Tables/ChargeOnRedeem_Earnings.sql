CREATE TABLE [MI].[ChargeOnRedeem_Earnings] (
    [ID]              INT      IDENTITY (1, 1) NOT NULL,
    [FanID]           INT      NOT NULL,
    [BrandID]         SMALLINT NOT NULL,
    [TransactionDate] DATE     NOT NULL,
    [EarnAmount]      MONEY    NOT NULL,
    [ChargeOnRedeem]  BIT      NOT NULL,
    [EligibleDate]    DATE     NULL,
    [ChargeTypeID]    TINYINT  CONSTRAINT [DF_MI_ChargeOnRedeem_Earnings_ChargeTypeID] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_MI_ChargeOnRedeem_Earnings] PRIMARY KEY CLUSTERED ([ID] ASC)
);

