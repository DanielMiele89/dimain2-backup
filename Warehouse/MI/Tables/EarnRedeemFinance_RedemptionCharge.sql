CREATE TABLE [MI].[EarnRedeemFinance_RedemptionCharge] (
    [ID]              INT     IDENTITY (1, 1) NOT NULL,
    [FanID]           INT     NOT NULL,
    [ChargeDate]      DATE    NOT NULL,
    [ChargeAmount]    MONEY   NOT NULL,
    [BrandID]         INT     NOT NULL,
    [ChargeTypeID]    TINYINT CONSTRAINT [DF_MI_EarnRedeemFinance_RedemptionCharge] DEFAULT ((0)) NOT NULL,
    [PaymentMethodID] TINYINT NOT NULL,
    [EarnID]          INT     NOT NULL,
    [RedemptionID]    INT     NOT NULL,
    [ChargeStatusID]  TINYINT NOT NULL,
    [IsRBS]           BIT     NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_RedemptionCharge] PRIMARY KEY CLUSTERED ([ID] ASC)
);

