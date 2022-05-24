CREATE TABLE [APW].[WeeklyNLECustomer] (
    [CINID]             INT  NOT NULL,
    [FanID]             INT  NOT NULL,
    [PublisherID]       INT  NOT NULL,
    [PreCumulativeDate] DATE NOT NULL,
    [PreReportDate]     DATE NOT NULL,
    [ReportPeriodDate]  DATE NOT NULL,
    CONSTRAINT [PK_Transform_WeeklyNLECustomer] PRIMARY KEY CLUSTERED ([CINID] ASC)
);

