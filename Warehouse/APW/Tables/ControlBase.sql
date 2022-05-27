CREATE TABLE [APW].[ControlBase] (
    [CINID]                  INT     NOT NULL,
    [FirstTranDate]          DATE    NULL,
    [FirstTranMonthID]       INT     NULL,
    [PseudoActivatedMonthID] INT     NULL,
    [PrePeriodStartDate]     DATE    NULL,
    [PrePeriodEndDate]       DATE    NULL,
    [PrePeriodSpendID]       TINYINT NULL,
    CONSTRAINT [PK_APW_ControlFirstSpend] PRIMARY KEY CLUSTERED ([CINID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IXNCL_APW_ControlBase_PrePeriodDateRange]
    ON [APW].[ControlBase]([PrePeriodStartDate] ASC, [PrePeriodEndDate] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

