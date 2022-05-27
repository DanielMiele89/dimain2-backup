CREATE TABLE [APW].[CustomersActive] (
    [FanID]              INT     NOT NULL,
    [CINID]              INT     NOT NULL,
    [ActivatedDate]      DATE    NOT NULL,
    [FirstTranDate]      DATE    NULL,
    [ActivatedMonthID]   INT     NULL,
    [FirstTranMonthID]   INT     NULL,
    [PrePeriodStartDate] DATE    NULL,
    [PrePeriodEndDate]   DATE    NULL,
    [PrePeriodSpendID]   TINYINT NULL,
    CONSTRAINT [PK_APW_CustomersActive] PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_FirstTranMonthID]
    ON [APW].[CustomersActive]([FirstTranMonthID] ASC)
    INCLUDE([ActivatedMonthID]) WITH (FILLFACTOR = 85);

