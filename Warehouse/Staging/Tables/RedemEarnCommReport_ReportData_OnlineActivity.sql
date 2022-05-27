CREATE TABLE [Staging].[RedemEarnCommReport_ReportData_OnlineActivity] (
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [PeriodID]          INT          NOT NULL,
    [YYYYMM]            VARCHAR (6)  NOT NULL,
    [MonthStart]        DATE         NOT NULL,
    [MonthEnd]          DATE         NOT NULL,
    [BookTypeValue]     VARCHAR (8)  NULL,
    [PaymentCardMethod] VARCHAR (50) NULL,
    [MarketableByEmail] BIT          NULL,
    [Registered]        BIT          NULL,
    [ActiveCustomers]   INT          NULL,
    [EmailOpeners]      INT          NULL,
    [WebsiteLogins_3M]  INT          NULL,
    [WebsiteLogins_12M] INT          NULL,
    [IsSummary]         INT          NOT NULL,
    [ReportDate]        DATE         NOT NULL,
    CONSTRAINT [PK_RedemEarnCommReport_ReportData_OnlineActivity] PRIMARY KEY CLUSTERED ([ID] ASC)
);

