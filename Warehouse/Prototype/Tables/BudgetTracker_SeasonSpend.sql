CREATE TABLE [Prototype].[BudgetTracker_SeasonSpend] (
    [ID]       INT      IDENTITY (1, 1) NOT NULL,
    [BrandID]  SMALLINT NOT NULL,
    [DayID]    SMALLINT NOT NULL,
    [DaySpend] MONEY    NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

