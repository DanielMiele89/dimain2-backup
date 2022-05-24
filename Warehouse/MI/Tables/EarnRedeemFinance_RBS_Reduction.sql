CREATE TABLE [MI].[EarnRedeemFinance_RBS_Reduction] (
    [ID]           INT   IDENTITY (1, 1) NOT NULL,
    [FanID]        INT   NOT NULL,
    [ChargeDate]   DATE  NOT NULL,
    [ChargeAmount] MONEY NOT NULL,
    [BrandID]      INT   NOT NULL,
    [EarnID]       INT   NOT NULL,
    [IsRBS]        BIT   NOT NULL,
    CONSTRAINT [PK_MI_EarnRedeemFinance_RBS_Reduction] PRIMARY KEY CLUSTERED ([ID] ASC)
);

