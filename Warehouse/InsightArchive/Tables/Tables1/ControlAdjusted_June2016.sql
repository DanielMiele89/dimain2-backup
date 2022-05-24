CREATE TABLE [InsightArchive].[ControlAdjusted_June2016] (
    [CINID]                  INT      NOT NULL,
    [FirstTranYear]          SMALLINT NOT NULL,
    [PrePeriodSpendID]       TINYINT  NOT NULL,
    [PrePeriodSpend]         MONEY    NOT NULL,
    [PrePeriodTranCount]     INT      NOT NULL,
    [PseudoActivatedMonthID] INT      NOT NULL,
    CONSTRAINT [PK_InsightArchive_ControlAdjusted_June2016] PRIMARY KEY CLUSTERED ([CINID] ASC)
);

