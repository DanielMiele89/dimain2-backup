CREATE TABLE [Staging].[RedemEarnCommReport_ReportData_Cashback] (
    [ID]                        INT          IDENTITY (1, 1) NOT NULL,
    [PeriodID]                  INT          NOT NULL,
    [MonthStart]                DATE         NOT NULL,
    [MonthEnd]                  DATE         NOT NULL,
    [BookTypeValue]             VARCHAR (8)  NULL,
    [PaymentMethodsAvailableID] INT          NULL,
    [DebitFlag]                 BIT          NULL,
    [CreditFlag]                BIT          NULL,
    [PaymentCardMethod]         VARCHAR (50) NULL,
    [CashbackOrigin]            VARCHAR (50) NULL,
    [ActiveCustomers]           INT          NULL,
    [MonthCashbackEarners]      INT          NULL,
    [MonthCashbackSum]          MONEY        NULL,
    [ReportDate]                DATE         NOT NULL,
    CONSTRAINT [PK_RedemEarnCommReport_ReportData_Cashback] PRIMARY KEY CLUSTERED ([ID] ASC)
);

