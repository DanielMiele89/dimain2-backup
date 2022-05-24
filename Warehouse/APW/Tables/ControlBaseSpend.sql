CREATE TABLE [APW].[ControlBaseSpend] (
    [CINID]              INT   NOT NULL,
    [PrePeriodSpend]     MONEY NOT NULL,
    [PrePeriodTranCount] INT   NOT NULL,
    CONSTRAINT [PK_APW_ControlBaseSpend] PRIMARY KEY CLUSTERED ([CINID] ASC)
);

