CREATE TABLE [APW].[ControlAdjustmentFactor] (
    [PseudoActivatedMonthID] INT        NOT NULL,
    [CustomerCountControl]   FLOAT (53) NOT NULL,
    [SpenderCountControl]    FLOAT (53) NOT NULL,
    [TranCountControl]       FLOAT (53) NOT NULL,
    [SpendControl]           MONEY      NOT NULL,
    [CustomerCountExposed]   FLOAT (53) NOT NULL,
    [SpenderCountExposed]    FLOAT (53) NOT NULL,
    [TranCountExposed]       FLOAT (53) NOT NULL,
    [SpendExposed]           MONEY      NOT NULL,
    [RRAdjustmentFactor]     FLOAT (53) NULL,
    [SPSAdjustmentFactor]    FLOAT (53) NULL,
    [ATVAdjustmentFactor]    FLOAT (53) NULL,
    [ATFAdjustmentFactor]    FLOAT (53) NULL,
    CONSTRAINT [PK_APW_ControlAdjustmentFactor] PRIMARY KEY CLUSTERED ([PseudoActivatedMonthID] ASC)
);

