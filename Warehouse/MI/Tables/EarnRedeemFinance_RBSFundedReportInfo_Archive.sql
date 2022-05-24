CREATE TABLE [MI].[EarnRedeemFinance_RBSFundedReportInfo_Archive] (
    [ID]                           INT           IDENTITY (1, 1) NOT NULL,
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
    [BankID]                       TINYINT       NULL,
    [ArchiveDate]                  DATETIME      CONSTRAINT [DF_MI_EarnRedeemFinance_RBSFundedReportInfo_Archive_ArchiveDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_RBSFundedReportInfo_Archive] PRIMARY KEY CLUSTERED ([ID] ASC)
);

