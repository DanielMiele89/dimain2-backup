CREATE TABLE [MI].[RedemptionCharge] (
    [ID]           INT   IDENTITY (1, 1) NOT NULL,
    [FanID]        INT   NOT NULL,
    [ChargeDate]   DATE  NOT NULL,
    [ChargeAmount] MONEY NOT NULL,
    [BrandID]      INT   NOT NULL,
    CONSTRAINT [PK_MI_RedemptionCharge] PRIMARY KEY CLUSTERED ([ID] ASC)
);

