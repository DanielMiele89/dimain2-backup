CREATE TABLE [MI].[EarnRedeemFinance_RBS_EligibleCustomers] (
    [ID]              TINYINT  IDENTITY (1, 1) NOT NULL,
    [BrandID]         SMALLINT NOT NULL,
    [PaymentMethodID] SMALLINT NOT NULL,
    [IsRBS]           BIT      NOT NULL,
    [ChargeTypeID]    TINYINT  NOT NULL,
    [EligibleCount]   INT      NOT NULL,
    [EarnedCount]     INT      NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_RBS_EligibleCustomers] PRIMARY KEY CLUSTERED ([ID] ASC)
);

