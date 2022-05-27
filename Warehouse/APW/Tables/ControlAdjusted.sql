CREATE TABLE [APW].[ControlAdjusted] (
    [CINID]                  INT      NOT NULL,
    [FirstTranYear]          SMALLINT NOT NULL,
    [PrePeriodSpendID]       TINYINT  NOT NULL,
    [PrePeriodSpend]         MONEY    NOT NULL,
    [PrePeriodTranCount]     INT      NOT NULL,
    [PseudoActivatedMonthID] INT      NOT NULL,
    CONSTRAINT [PK_APW_ControlAdjusted] PRIMARY KEY CLUSTERED ([CINID] ASC)
);

