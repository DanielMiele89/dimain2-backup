CREATE TABLE [MI].[EarnRedeemFinance_RBS_Totals_WG] (
    [ID]                 INT      IDENTITY (1, 1) NOT NULL,
    [BrandID]            SMALLINT NOT NULL,
    [PaymentMethodID]    TINYINT  NOT NULL,
    [ChargeTypeID]       TINYINT  NOT NULL,
    [IsRBS]              BIT      NOT NULL,
    [Earnings]           MONEY    NOT NULL,
    [RedemptionValue]    MONEY    NOT NULL,
    [EligibleEarnings]   MONEY    NOT NULL,
    [IneligibleEarnings] MONEY    NOT NULL,
    [NoLiability]        MONEY    NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_RBS_Totals_WG] PRIMARY KEY CLUSTERED ([ID] ASC)
);

