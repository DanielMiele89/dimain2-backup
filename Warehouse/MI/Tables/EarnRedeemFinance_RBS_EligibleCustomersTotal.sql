CREATE TABLE [MI].[EarnRedeemFinance_RBS_EligibleCustomersTotal] (
    [ID]                   TINYINT IDENTITY (1, 1) NOT NULL,
    [EligibleCountNatWest] INT     NOT NULL,
    [EliglbleCountRBS]     INT     NOT NULL,
    [EarnedCountNatWest]   INT     NOT NULL,
    [EarnedCountRBS]       INT     NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_RBS_EligibleCustomersTotal] PRIMARY KEY CLUSTERED ([ID] ASC)
);

