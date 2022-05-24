CREATE TABLE [MI].[EarnRedeemFinance_RBS_Earnings] (
    [ID]              INT           IDENTITY (1, 1) NOT NULL,
    [FanID]           INT           NOT NULL,
    [BrandID]         SMALLINT      NOT NULL,
    [TransactionDate] DATE          NOT NULL,
    [EarnAmount]      MONEY         NOT NULL,
    [EligibleDate]    DATE          NULL,
    [ChargeTypeID]    TINYINT       CONSTRAINT [DF_MI_EarnRedeemFinance_RBS_Earnings_ChargeTypeID] DEFAULT ((0)) NOT NULL,
    [PaymentMethodID] TINYINT       NOT NULL,
    [IsRBS]           BIT           NOT NULL,
    [AwardType]       VARCHAR (100) NULL,
    [EarnRedeemable]  MONEY         NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_RBS_Earnings] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EarnRedeemFinance_RBS_Earnings_Preaggregate]
    ON [MI].[EarnRedeemFinance_RBS_Earnings]([TransactionDate] ASC)
    INCLUDE([FanID], [BrandID], [EarnAmount], [EligibleDate], [ChargeTypeID], [PaymentMethodID], [IsRBS]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

