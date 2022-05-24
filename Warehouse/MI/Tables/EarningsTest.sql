CREATE TABLE [MI].[EarningsTest] (
    [ID]              INT      IDENTITY (1, 1) NOT NULL,
    [FanID]           INT      NOT NULL,
    [BrandID]         SMALLINT NOT NULL,
    [TransactionDate] DATE     NOT NULL,
    [EarnAmount]      MONEY    NOT NULL,
    [ChargeOnRedeem]  BIT      NOT NULL
);

