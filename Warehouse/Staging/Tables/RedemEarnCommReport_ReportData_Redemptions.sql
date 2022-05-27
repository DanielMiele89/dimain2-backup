CREATE TABLE [Staging].[RedemEarnCommReport_ReportData_Redemptions] (
    [ID]                        INT          IDENTITY (1, 1) NOT NULL,
    [PeriodID]                  INT          NOT NULL,
    [RollingMonthStart]         DATE         NOT NULL,
    [RollingMonthEnd]           DATE         NOT NULL,
    [BookTypeValue]             VARCHAR (8)  NULL,
    [PaymentMethodsAvailableID] INT          NULL,
    [DebitFlag]                 BIT          NULL,
    [CreditFlag]                BIT          NULL,
    [PaymentCardMethod]         VARCHAR (50) NULL,
    [RedemptionsCount]          INT          NULL,
    [ActiveCustomers]           INT          NULL,
    [RedeemersCount12M]         INT          NULL,
    [YTDRedeemersCount]         INT          NULL,
    [IsSummary]                 INT          NOT NULL,
    [ReportDate]                DATE         NOT NULL,
    CONSTRAINT [PK_RedemEarnCommReport_ReportData_Redemptions] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [Staging].[RedemEarnCommReport_ReportData_Redemptions]([IsSummary] ASC, [PeriodID] ASC, [ReportDate] ASC) WITH (FILLFACTOR = 80);

