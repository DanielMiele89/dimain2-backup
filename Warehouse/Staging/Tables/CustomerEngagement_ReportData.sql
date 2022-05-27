CREATE TABLE [Staging].[CustomerEngagement_ReportData] (
    [ID]                  INT          IDENTITY (1, 1) NOT NULL,
    [SegmentStartDate]    DATE         NULL,
    [SegmentEndDate]      DATE         NULL,
    [EngagementSegment]   VARCHAR (30) NULL,
    [MonthCommencing]     DATE         NULL,
    [PercentDebitOnly]    FLOAT (53)   NULL,
    [PercentCreditOnly]   FLOAT (53)   NULL,
    [PercentDebitCredit]  FLOAT (53)   NULL,
    [PercentLoggedIn]     FLOAT (53)   NULL,
    [PercentOpenedEmail]  FLOAT (53)   NULL,
    [WLsPerCus]           FLOAT (53)   NULL,
    [EOsPerCus]           FLOAT (53)   NULL,
    [PercentEarnedOnDDs]  FLOAT (53)   NULL,
    [PercentEarnedOnMFs]  FLOAT (53)   NULL,
    [SPC_MFoffers]        FLOAT (53)   NULL,
    [DDearningsPerCus]    FLOAT (53)   NULL,
    [CCearningsPerCus]    FLOAT (53)   NULL,
    [MFearningsPerCus]    FLOAT (53)   NULL,
    [TotalEarningsPerCus] FLOAT (53)   NULL,
    CONSTRAINT [PK_CustomerEngagement_ReportData] PRIMARY KEY CLUSTERED ([ID] ASC)
);

