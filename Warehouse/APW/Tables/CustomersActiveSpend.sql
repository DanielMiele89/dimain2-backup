CREATE TABLE [APW].[CustomersActiveSpend] (
    [CINID]              INT   NOT NULL,
    [PrePeriodSpend]     MONEY NOT NULL,
    [PrePeriodTranCount] INT   NOT NULL,
    CONSTRAINT [PK_APW_CustomersActiveSpend] PRIMARY KEY CLUSTERED ([CINID] ASC)
);

