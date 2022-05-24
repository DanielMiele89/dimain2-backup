CREATE TABLE [MI].[ChargeOnRedeem_MonthTotals] (
    [ID]                           INT      IDENTITY (1, 1) NOT NULL,
    [YearNumber]                   SMALLINT NOT NULL,
    [MonthNumber]                  TINYINT  NOT NULL,
    [PartnerID]                    INT      NOT NULL,
    [EarnedTotalMonth]             MONEY    NOT NULL,
    [EarnedTotalCumulative]        MONEY    NOT NULL,
    [RedeemedTotalMonth]           MONEY    NOT NULL,
    [RedeemedTotalCumulative]      MONEY    NOT NULL,
    [EarnedEligibleMonth]          MONEY    NOT NULL,
    [EarnedEligibleCumulative]     MONEY    NOT NULL,
    [EarnedPendingMonth]           MONEY    NOT NULL,
    [EarnedPendingCumulative]      MONEY    NOT NULL,
    [EligibleCustomerCount]        INT      NOT NULL,
    [EligiblePendingCustomerCount] INT      NOT NULL,
    [BankID]                       TINYINT  NULL,
    CONSTRAINT [PK_MI_ChargeOnRedeem_MonthTotals] PRIMARY KEY CLUSTERED ([ID] ASC)
);

