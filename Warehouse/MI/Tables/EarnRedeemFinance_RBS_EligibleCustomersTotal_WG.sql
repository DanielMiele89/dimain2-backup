CREATE TABLE [MI].[EarnRedeemFinance_RBS_EligibleCustomersTotal_WG] (
    [ID]                   TINYINT IDENTITY (1, 1) NOT NULL,
    [EligibleCountNatWest] INT     NOT NULL,
    [EliglbleCountRBS]     INT     NOT NULL,
    [EarnedCountNatWest]   INT     NOT NULL,
    [EarnedCountRBS]       INT     NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_RBS_EligibleCustomersTotal_WG] PRIMARY KEY CLUSTERED ([ID] ASC)
);

