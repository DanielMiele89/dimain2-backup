CREATE TABLE [MI].[EarnRedeemFinance_EarnRedeemByMonth_Archive] (
    [ID]              INT      IDENTITY (1, 1) NOT NULL,
    [ArchiveDate]     DATE     CONSTRAINT [DF_MI_EarnRedeemFinance_EarnRedeemByMonth_Archive_ArchiveDate] DEFAULT (getdate()) NULL,
    [MonthDate]       DATE     NOT NULL,
    [BrandID]         SMALLINT NOT NULL,
    [Earnings]        MONEY    NOT NULL,
    [RedemptionValue] MONEY    NOT NULL,
    [ChargeTypeID]    TINYINT  NOT NULL,
    [PaymentMethodID] TINYINT  NOT NULL,
    [IsRBS]           BIT      NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_EarningsByMonth_Archive] PRIMARY KEY CLUSTERED ([ID] ASC)
);

