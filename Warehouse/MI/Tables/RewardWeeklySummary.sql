CREATE TABLE [MI].[RewardWeeklySummary] (
    [ID]                     INT          IDENTITY (1, 1) NOT NULL,
    [PartnerID]              INT          NOT NULL,
    [PartnerName]            VARCHAR (50) NOT NULL,
    [SalesWeek]              MONEY        NOT NULL,
    [SalesCumul]             MONEY        NOT NULL,
    [TranCountWeek]          INT          NOT NULL,
    [TranCountCumul]         INT          NOT NULL,
    [UniqueSpendersWeek]     INT          NOT NULL,
    [UniqueSpendersCumul]    INT          NOT NULL,
    [TargetedCustomersWeek]  INT          NOT NULL,
    [TargetedCustomersCumul] INT          NOT NULL,
    [CommissionWeek]         MONEY        NOT NULL,
    [CommissionCumul]        MONEY        NOT NULL,
    [WeekStartDate]          DATE         NOT NULL,
    [WeekEndDate]            DATE         NOT NULL,
    [CumulativeDate]         DATE         NOT NULL,
    [SalesWeekOnline]        MONEY        NOT NULL,
    [SalesCumulOnline]       MONEY        NOT NULL,
    [CommissionWeekOnline]   MONEY        NOT NULL,
    [CommissionCumulOnline]  MONEY        NOT NULL,
    CONSTRAINT [PK_MI_RewardWeeklySummary] PRIMARY KEY CLUSTERED ([ID] ASC)
);

