CREATE TABLE [Staging].[RedemEarnCommReport_ReportData_CashbackBalance] (
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [PeriodID]          INT          NOT NULL,
    [MonthEnd]          DATE         NOT NULL,
    [PaymentCardMethod] VARCHAR (50) NOT NULL,
    [Registered]        BIT          NOT NULL,
    [Accounts]          INT          NULL,
    [ClubCashPending]   MONEY        NULL,
    [ReportDate]        DATE         NULL,
    CONSTRAINT [PK_RedemEarnCommReport_ReportData_CashbackBalance] PRIMARY KEY CLUSTERED ([ID] ASC)
);

