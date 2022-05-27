CREATE TABLE [APW].[WeeklyNLECustomer_Stage] (
    [FanID]             INT  NOT NULL,
    [PublisherID]       INT  NOT NULL,
    [PreCumulativeDate] DATE NOT NULL,
    [PreReportDate]     DATE NOT NULL,
    [ReportPeriodDate]  DATE NOT NULL,
    CONSTRAINT [PK_Transform_WeeklyNLECustomer_Stage] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

