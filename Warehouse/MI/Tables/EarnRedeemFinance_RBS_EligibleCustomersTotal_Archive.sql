CREATE TABLE [MI].[EarnRedeemFinance_RBS_EligibleCustomersTotal_Archive] (
    [ID]                   TINYINT  IDENTITY (1, 1) NOT NULL,
    [EligibleCountNatWest] INT      NOT NULL,
    [EliglbleCountRBS]     INT      NOT NULL,
    [EarnedCountNatWest]   INT      NOT NULL,
    [EarnedCountRBS]       INT      NOT NULL,
    [ArchiveDate]          DATETIME CONSTRAINT [DF_MI_EarnRedeemFinance_RBS_EligibleCustomersTotal_Archive_ArchiveDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_RBS_EligibleCustomersTotal_Archive] PRIMARY KEY CLUSTERED ([ID] ASC)
);

