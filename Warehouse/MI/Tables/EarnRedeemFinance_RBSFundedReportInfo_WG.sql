CREATE TABLE [MI].[EarnRedeemFinance_RBSFundedReportInfo_WG] (
    [YearNumber]                   SMALLINT      NULL,
    [MonthNumber]                  TINYINT       NULL,
    [PartnerID]                    INT           NULL,
    [PartnerName]                  VARCHAR (100) NULL,
    [EarnedTotalMonth]             MONEY         NULL,
    [EarnedTotalCumulative]        MONEY         NULL,
    [RedeemedTotalMonth]           MONEY         NULL,
    [RedeemedTotalCumulative]      MONEY         NULL,
    [EarnedEligibleMonth]          MONEY         NULL,
    [EarnedEligibleCumulative]     MONEY         NULL,
    [EarnedPendingMonth]           MONEY         NULL,
    [EarnedPendingCumulative]      MONEY         NULL,
    [EligibleCustomerCount]        INT           NULL,
    [EligiblePendingCustomerCount] INT           NULL,
    [BankID]                       TINYINT       NULL
);

