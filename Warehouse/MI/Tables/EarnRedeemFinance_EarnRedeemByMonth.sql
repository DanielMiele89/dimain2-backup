CREATE TABLE [MI].[EarnRedeemFinance_EarnRedeemByMonth] (
    [ID]              INT      IDENTITY (1, 1) NOT NULL,
    [MonthDate]       DATE     NOT NULL,
    [BrandID]         SMALLINT NOT NULL,
    [Earnings]        MONEY    NOT NULL,
    [RedemptionValue] MONEY    NOT NULL,
    [ChargeTypeID]    TINYINT  NOT NULL,
    [PaymentMethodID] TINYINT  NOT NULL,
    [IsRBS]           BIT      NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_EarningsByMonth] PRIMARY KEY CLUSTERED ([ID] ASC)
);

